require_relative "./badge_downloader"
require_relative "./rubygems_api"

class CelluloidManager 
  include Celluloid
  include Celluloid::Notifications
  include Celluloid::Logger
    
  @attributes = [:jobs,:job_to_worker , :worker_to_job, :params, :condition]
 
  attr_accessor *@attributes
  
  attr_reader :worker_supervisor
  trap_exit :worker_died
  finalizer :finalize
  
  
  def initialize
    @condition = Celluloid::Condition.new
    @worker_supervisor = Celluloid::SupervisionGroup.run!
     
    @worker_supervisor.supervise_as(:badge_downloader, BadgeDownloader)
    @jobs = {}
    @job_to_worker = {}
    @worker_to_job = {}
  end
 
  def finalize
    terminate
  end
   
  
  def delegate(params)
    job_id = @jobs.size + 1 
    @jobs[job_id] = params
    params['job_id'] = job_id
    @worker_supervisor.supervise_as(:rubygems_api, RubygemsApi, params )
    #debug(@jobs)
    #start work and send it to the background
    Celluloid::Actor[:badge_downloader].work(params, Celluloid::Actor[:rubygems_api], Actor.current)
  end
    
  #call back from actor once it has received it's job
  #actor should do this asap
  def register_worker_for_job(job, worker)
    job = job.stringify_keys
    if job['job_id'].blank?
      delegate(job)
    else
      @job_to_worker[job['job_id']] = worker
      @worker_to_job[worker.mailbox.address] = job
      Actor.current.link worker
      # puts "Worker who called back for job: #{job.inspect} was #{worker.inspect}"
      blk = lambda do |sum|
        @condition.signal(sum)
      end
      worker.async.fetch_image_badge_svg(blk)
      return  @condition.wait
    end
  end
   
  def worker_died(worker, reason)
    job = @worker_to_job[worker.mailbox.address]
    @worker_to_job.delete(worker.mailbox.address)
    info "restarting #{job} on new worker" 
    if job.present?
      delegate(job)
    end
  end 
    
end


