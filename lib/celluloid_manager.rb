require_relative "./badge_downloader"
require_relative "./rubygems_api"

class CelluloidManager 
  include Celluloid
  include Celluloid::Logger
    
  @attributes = [:jobs,:job_to_worker , :worker_to_job, :params]
 
  attr_accessor *@attributes
  
  attr_reader :worker_supervisor, :workers, :gem_workers
  trap_exit :worker_died
  
  
  def initialize
    @worker_supervisor = Celluloid::SupervisionGroup.run!
   
    @jobs = {}
    @job_to_worker = {}
    @worker_to_job = {}
    @gem_workers = @worker_supervisor.pool(RubygemsApi, as: :gem_workers, size: 10)
    @workers = @worker_supervisor.pool(BadgeDownloader, as: :workers, size: 10)
  end
 
  
  
  def delegate(params)
    job_id = @jobs.size + 1 
    params["job_id"] = job_id
    @jobs[job_id] = params
    @workers.future.work(params, @gem_workers).value
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


