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
    @jobs = {}
    @job_to_worker = {}
    @worker_to_job = {}
    @worker_supervisor = Celluloid::SupervisionGroup.run!
    @worker_supervisor.supervise_as(:rubygems_api, RubygemsApi) if Celluloid::Actor[:rubygems_api].blank?
    @worker_supervisor.supervise_as(:badge_downloader, BadgeDownloader) if Celluloid::Actor[:badge_downloader].blank?
  end
 
 
  
  def delegate(blk, params)
    job_id = @jobs.size + 1 
    params["job_id"] = job_id
    @jobs[job_id] = params
    Celluloid::Actor[:badge_downloader].async.work(params, blk,  "rubygems_api")
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


