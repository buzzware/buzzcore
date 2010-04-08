#gem_root = File.expand_path(File.join(File.dirname(__FILE__), ".."))
#Cms.add_to_rails_paths gem_root
#
#throw RuntimeError.new('thumbs_cache folder must exist') unless File.exists? APP_CONFIG[:thumbs_cache]
#
#Cms::PageHelper.module_eval do
#
#	extend BcmsTools::PageHelper
#
#end
#
config.after_initialize do
	#Buzzcore::Tweaks.rails_config = config
	Buzzcore::Tweaks.load_all(File.join(File.dirname(__FILE__),'../tweaks'))
	Buzzcore::Tweaks.load_all(File.join(RAILS_ROOT,'tweaks'))
end
