class GroupsController < ApplicationController

  def index
    # people/1/groups
    if params[:person_id]
      @person = Person.find(params[:person_id])
      respond_to do |format|
        format.js   { render partial: 'person_groups' }
        format.html { render action: 'index_for_person' }
        if can_export?
          format.xml { render xml:  @person.groups.to_xml(except: %w(site_id)) }
        end
      end
    # /groups?category=Small+Groups
    # /groups?name=college
    elsif params[:category] or params[:name]
      @categories = Group.category_names
      @groups = Group.all
      @groups.where!(hidden: false, approved: true) unless @logged_in.admin?(:manage_groups)
      @groups.where!(category: params[:category]) if params[:category].present?
      @groups.where!('name like ?', "%#{params[:name]}%") if params[:name].present?
      @groups.order!(:name)
      @hidden_groups = @groups.where(hidden: true)
      respond_to do |format|
        format.html { render action: 'search' }
        format.js
        if can_export?
          format.xml { render xml:  @groups.to_xml(except: %w(site_id)) }
        end
      end
    # /groups
    else
      @categories = Group.category_names
      if @logged_in.admin?(:manage_groups)
        @unapproved_groups = Group.unapproved
      else
        @unapproved_groups = Group.unapproved.where(creator_id: @logged_in.id)
      end
      @person = @logged_in
      respond_to do |format|
        format.html
        if can_export?
          format.xml do
            job = Group.create_to_xml_job
            redirect_to generated_file_path(job.id)
          end
          format.csv do
            job = Group.create_to_csv_job
            redirect_to generated_file_path(job.id)
          end
        end
      end
    end
  end

  def show
    @group = Group.find(params[:id])
    if not (@group.approved? or @group.admin?(@logged_in))
      render text: t('groups.pending_approval.this_group'), layout: true
    elsif @logged_in.can_see?(@group)
      @members = @group.people.minimal
      @member_of = !!@logged_in.member_of?(@group)
      @stream_items = StreamItem.shared_with(@logged_in).where(group: @group).paginate(page: params[:timeline_page], per_page: 5)
      @pictures = @group.album_pictures.references(:album)
      @pictures.where!('albums.is_public' => true) unless @logged_in.member_of?(@group)
    else
      render action: 'show_limited'
    end
  end

  def new
    @group = @logged_in.new_group_creation
  end

  def create
    @group = @logged_in.new_group_creation(group_params)
    if @group.save
      flash[:notice] = if @group.pending_approval?
        t('groups.created_pending_approval')
      else
        t('groups.created')
      end
      redirect_to @group
    else
      render :new
    end
  end

  def edit
    @group ||= Group.find(params[:id])
    if @logged_in.can_edit?(@group)
      @categories = Group.categories.keys
      @members = @group.people.minimal.order('last_name, first_name')
    else
      render text: t('not_authorized'), layout: true, status: 401
    end
  end

  def update
    @group = Group.find(params[:id])
    if @logged_in.can_edit?(@group)
      params[:group][:photo] = nil if params[:group][:photo] == 'remove'
      params[:group].cleanse 'address'
      if @group.update_attributes(group_params)
        flash[:notice] = t('groups.saved')
        redirect_to @group
      else
        edit; render action: 'edit'
      end
    else
      render text: t('not_authorized'), layout: true, status: 401
    end
  end

  def destroy
    @group = Group.find(params[:id])
    if @logged_in.can_delete?(@group)
      @group.destroy
      flash[:notice] = t('groups.deleted')
      redirect_to groups_path
    else
      render text: t('not_authorized'), layout: true, status: 401
    end
  end

  def batch
    if @logged_in.admin?(:manage_groups)
      if request.post?
        @errors = []
        @groups = Group.order('category, name')
        @groups.each do |group|
          if vals = params[:groups][group.id.to_s]
            group.attributes = vals.permit(*group_attributes)
            if group.changed?
              unless group.save
                @errors << [group.id, group.errors.full_messages]
              end
            end
          end
        end
      else
        @groups = Group.order('category, name')
      end
    else
      render text: t('not_authorized'), layout: true, status: 401
    end
  end

  private

  def group_attributes
    base = [:name, :description, :photo, :meets, :location, :directions, :other_notes, :address, :members_send, :private, :category, :leader_id, :blog, :email, :prayer, :attendance, :gcal_private_link, :approval_required_to_join, :pictures, :cm_api_list_id]
    base += [:approved, :link_code, :parents_of, :hidden] if @logged_in.admin?(:manage_groups)
    base
  end

  def group_params
    params.require(:group).permit(*group_attributes)
  end

  def feature_enabled?
    unless Setting.get(:features, :groups)
      redirect_to people_path
      false
    end
  end

end
