require_relative "./badge_downloader"
require_relative "./rubygems_api"

class CelluloidManager 
  include Celluloid
  include Celluloid::Logger
    
  @attributes = [:jobs,:job_to_worker , :worker_to_job, :params, :condition]
 
  attr_accessor *@attributes
  
  attr_reader :worker_supervisor, :workers, :gem_workers
  trap_exit :worker_died
  finalizer :finalize
  
  
  def initialize
    @condition = Celluloid::Condition.new
    @worker_supervisor = Celluloid::SupervisionGroup.run!
   
    @jobs = {}
    @job_to_worker = {}
    @worker_to_job = {}
    @gem_workers = @worker_supervisor.pool(RubygemsApi, as: :gem_workers, size: 10)
    @workers = @worker_supervisor.pool(BadgeDownloader, as: :workers, size: 10)
  end
 
  def finalize
    terminate 
  end
   
  
  def delegate(params)
    job_id = @jobs.size + 1 
    params["job_id"] = job_id
    @jobs[job_id] = params
    rubygems_api =  @gem_workers.future.work(params).value
    @workers.future.work(Actor.current, params, rubygems_api).value
  end
  
  def register_worker_for_job(job, worker)
    job = job.stringify_keys
    
    worker.job_id = job['job_id'] if worker.job_id.blank?
    @job_to_worker[job['job_id']] = worker
    @worker_to_job[worker.mailbox.address] = job
    Actor.current.link worker    
    blk = lambda do |sum|
      @condition.signal(sum)
    end
    worker.async.fetch_image_badge_svg(blk)
    return  @condition.wait
    # puts "Worker who called back for job: #{job.inspect} was #{worker.inspect}"
  end
  
  def worker_died(worker, reason)
    job = @worker_to_job[worker.mailbox.address]
    @worker_to_job.delete(worker.mailbox.address)
    info "restarting #{job} on new worker" 
    if job.present? && job["worker_action"].blank?
      job["worker_action"] = "rollback"
      delegate(job)
    end
  end 
    
end


