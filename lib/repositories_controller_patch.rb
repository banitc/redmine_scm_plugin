require_dependency 'repositories_controller'

module RepositoriesControllerPatch

    def self.included(base)
        base.extend(ClassMethods)
        base.send(:include, InstanceMethods)
        base.class_eval do
            unloadable
            alias_method_chain :edit, :add
        end
    end

    module ClassMethods
    end

    module InstanceMethods

        # NOTE: is a copy of RepositoriesController::edit
        def edit_with_add
            @repository = @project.repository
            if !@repository
                @repository = Repository.factory(params[:repository_scm])
                @repository.project = @project if @repository
            end
            if request.post? && @repository
                RAILS_DEFAULT_LOGGER.info params[:add].inspect
                if params[:operation].present? && params[:operation] == 'add'
                    if params[:repository]
                        matches = Regexp.new("^file://#{Regexp.escape(Svn['path'])}/([^/]+)/?$").match(params[:repository]['url'])
                        if matches
                            if File.directory?("#{Svn['path']}/#{matches[1]}")
                                @repository.errors.add(:url, :already_exists)
                            else
                                system("#{Svn['svnadmin']} create #{Svn['path']}/#{matches[1]}")
                            end
                        else
                            @repository.errors.add(:url, :should_be_of_format_local, :svn_path => Svn['path'])
                        end
                    end
                end
                @repository.attributes = params[:repository]
                if @repository.errors.empty?
                    @repository.save
                end
            end
            render(:update) do |page|
                page.replace_html("tab-content-repository", :partial => 'projects/settings/repository')
                if @repository && !@project.repository
                    @project.reload
                    page.replace_html("main-menu", render_main_menu(@project))
                end
            end
        end

    end

end