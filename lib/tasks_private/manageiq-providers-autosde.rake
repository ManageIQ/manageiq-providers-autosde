 namespace "manageiq:providers:autosde" do
   desc "bk Explaining what the task does"
   task :my do
     puts "AAAAAAAAAAAAAAAA"
     puts File.dirname(__FILE__)
     puts ManageIQ::Providers::Autosde::Engine.root
   end
 end
