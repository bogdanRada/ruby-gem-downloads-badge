require_relative "./badge_downloader"
require_relative "./rubygems_api"

class CelluloidManager 
  include Celluloid
  include Celluloid::Logger
    
  @attributes = [:jobs,:job_to_worker , :worker_to_job, :params, :condition, :actor_system, :worker_supervisor, :gem_workers, :workers]
 
  attr_accessor *@attributes
  
  attr_reader :worker_supervisor, :workers
  trap_exit :worker_died
  finalizer :finalize
  
  
  def initialize
    @condition = Celluloid::Condition.new
    @worker_supervisor = Celluloid::SupervisionGroup.run!
   
    @actor_system =   Celluloid.boot
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
    @jobs[job_id] = params
  
    rubygems_api =  @gem_workers.future.work(params).value

    worker =  @workers.future.work(params, rubygems_api).value
    
    @job_to_worker[job_id] = worker
    @worker_to_job[worker.mailbox.address] = params
    # puts "Worker who called back for job: #{job.inspect} was #{worker.inspect}"
    blk = lambda do |sum|
      @condition.signal(sum)
    end
    worker.async.fetch_image_badge_svg(blk)
    return  @condition.wait
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


