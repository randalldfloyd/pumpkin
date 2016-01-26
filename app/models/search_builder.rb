class SearchBuilder < CurationConcerns::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior

  def self.show_actions
    [:show, :manifest, :structure, :pdf]
  end

  def hide_parented_resources(solr_params)
    return if show_action? || bulk_edit?
    solr_params[:fq] ||= []
    solr_params[:fq] << "!#{ActiveFedora::SolrQueryBuilder.solr_name('ordered_by', :symbol)}:['' TO *]"
  end

  def join_from_parent(solr_params)
    return if show_action?
    solr_params[:q] = "(#{child_to_parent_query}{!dismax}#{solr_params[:q]}) OR ({!dismax}#{solr_params[:q]}) OR (#{file_set_to_resource_query}{!dismax}#{solr_params[:q]}) OR (#{child_to_parent_query}#{file_set_to_resource_query}{!dismax}#{solr_params[:q]})"
  end

  def show_action?
    self.class.show_actions.include? blacklight_params["action"].to_sym
  end

  def bulk_edit?
    blacklight_params["action"].to_sym == :bulk_edit
  end

  private

    def child_to_parent_query
      "{!join from=ordered_by_ssim to=id}"
    end

    def file_set_to_resource_query
      "{!join from=generic_work_ids_ssim to=id}"
    end
end
