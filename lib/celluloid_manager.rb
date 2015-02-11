require_relative "./badge_downloader"
require_relative "./rubygems_api"

class CelluloidManager 
  include Celluloid
  include Celluloid::Notifications
  include Celluloid::Logger
    
  @attributes = [:jobs,:job_to_worker , :worker_to_job, :params, :condition]
 
  attr_accessor *@attributes
  
  attr_reader :worker_supervisor, :workers
  trap_exit :worker_died
  finalizer :finalize
  
  
  def initialize(params, options = {})
    @condition = Celluloid::Condition.new
    @params = params
    @worker_supervisor = Celluloid::SupervisionGroup.run!
     
    @worker_supervisor.supervise_as(:rubygems_api, RubygemsApi, params )
    @worker_supervisor.supervise_as(:badge_downloader, BadgeDownloader, params, Celluloid::Actor[:rubygems_api] )
  end
 
  def finalize
    terminate
  end
   
 
  def work
    blk = lambda do |sum|
      @condition.signal(sum)
    end
    Celluloid::Actor[:badge_downloader] .async.fetch_image_badge_svg(blk)
    return  @condition.wait
  end
  
  def worker_died(worker, reason)
    job = @worker_to_job[worker.mailbox.address]
    @worker_to_job.delete(worker.mailbox.address)
    p "restarting #{job} on new worker" if $DEBUG
    if job.present? && job['action'] !=  "deploy:rollback"
      job = job.merge({ :action => "deploy:rollback"})
      delegate(job)
    end
  end 
    
    
    
end


