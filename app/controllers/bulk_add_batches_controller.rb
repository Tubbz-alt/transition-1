require 'view/mappings/canonical_filter'

class BulkAddBatchesController < ApplicationController
  include PaperTrail::Rails::Controller

  before_filter :find_site
  checks_user_can_edit
  before_filter :find_batch, only: [:preview, :import]

  def new
    paths = params[:paths].present? ? params[:paths].split(',') : []
    @batch = BulkAddBatch.new(paths: paths)
  end

  def create
    @batch = BulkAddBatch.new(type:     batch_params[:type],
                               new_url:  batch_params[:new_url],
                               tag_list: batch_params[:tag_list],
                               paths:    batch_params[:paths].split(/\r?\n|\r/).map(&:strip))
    @batch.user = current_user
    @batch.site = @site

    if @batch.save
      redirect_to preview_site_bulk_add_batch_path(@site, @batch, return_path: params[:return_path])
    else
      render action: 'new'
    end
  end

  def preview
  end

  def import
    if @batch.state == 'unqueued'
      @batch.update_attributes!(
        update_existing: batch_params[:update_existing],
        tag_list:        batch_params[:tag_list],
        state:           'queued')
      if @batch.invalid?
        render action: 'create' and return
      end

      if @batch.entries_to_process.count > 20
        MappingsBatchWorker.perform_async(@batch.id)
        flash[:show_background_batch_progress_modal] = true
      else
        @batch.process
        @batch.update_column(:seen_outcome, true)

        outcome = BatchOutcomePresenter.new(@batch)
        flash[:saved_mapping_ids] = outcome.affected_mapping_ids
        flash[:success] = outcome.success_message
        flash[:saved_operation] = outcome.analytics_event_type
      end
    end

    if Transition::OffSiteRedirectChecker.on_site?(params[:return_path])
      redirect_to params[:return_path]
    else
      redirect_to site_mappings_path(@site)
    end
  end

private
  def batch_params
    params.permit(:type,
                  :paths,
                  :new_url,
                  :tag_list,
                  :update_existing)
  end

  def find_site
    @site = Site.find_by_abbr!(params[:site_id])
  end

  def find_batch
    @batch = @site.bulk_add_batches.find(params[:id])
  end
end
