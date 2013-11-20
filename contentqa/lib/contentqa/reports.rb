require 'v1/repository'
require 'fileutils'

module Contentqa

  module Reports
    
    JOBS_DATABASE = 'jobs'

#    @dpla_db = CouchRest.database("http://162.209.12.195:5984/dpla")
#    @dashboard_db = CouchRest.database("http://162.209.12.195:5984/dashboard")
     #@dpla_db = CouchRest.database("http://camp.dpla.berkman.temphost.net:5981/dpla")
     #@dashboard_db = CouchRest.database("http://camp.dpla.berkman.temphost.net:5981/dashboard")
     @dashboard_db = V1::Repository.database(V1::Repository.cluster_endpoint('reader', 'dashboard'))
     @dpla_db = V1::Repository.database(V1::Repository.cluster_endpoint('reader', 'dpla'))
     @base_path = "/tmp/camp81/reports"


    # Get the document describing an ingest from the dashboard database
    def self.find_ingest(id)
      @dashboard_db.get(id)
    end

    # Get the list of available reports (defined as the qa_reports views in the dpla database)
    def self.find_report_types
      @dpla_db.get('_design/qa_reports')['views'].keys.sort
    end

    # Get the list of providers for whom data has been ingested
    def self.find_providers
      @dashboard_db.view('all_ingestion_docs/by_provider_name',{:include_docs => true})['rows']
    end

    # Find the list containing the most recent ingest for each provider
    def self.find_last_ingests
      output = []
      last = nil
      sorted = self.find_providers.sort {|x,y| x['key'] == y['key'] ? y['value'] <=> x['value'] : x['key'] <=> y['key'] } 
      sorted.each do |a|
        output << a if a['key'] != last
        last = a['key']
      end
      output
    end

    # Get a File::Stat object for the report if it has been generated
    def self.get_report (id, view)
      path = report_path id, view
      File.stat(path) if path and File.exists? path 
    end

    def self.is_safe_path? (path)
      path.match Regexp.new('^' + Regexp.escape(@base_path))
    end
    
    # Get the path on disk where report would exists. Reports are organized by ingestion document id and report name
    def self.report_path (id, view)
      path = File.expand_path(File.join(@base_path, id, view))
      path if is_safe_path?(path) and find_report_types.include? view
    end

    # Remove the provider from the row key
    def self.filter (row)
       filtered_row = {:key => row['key'].last, :value => row['value']} 
    end
    
    # Convert one line of a key/value JSON response pair into a line for a CSV file
    def self.csvify (row)
      "\"#{row[:key]}\",\"#{row[:value]}\"\n"
    end

    # Temporary file location while downloading
    def self.download_path (path)
      path + ".downloading"
    end

    def self.is_group_view? (view_name)
      view_name.end_with? "_count"
    end

    # Create a report
    def self.create_report (id, view)
      path = report_path id, view
      provider = find_ingest(id)['provider']
      if path 
        FileUtils.mkpath File.dirname(path) if not File.exists? File.dirname(path)
        view_name = "qa_reports/%{view}" % {:view => view}
        options = {:startkey => [provider, "0"], :endkey => [provider, "Z"]}
        if is_group_view?(view)
            options[:group] = true
        end
        File.open(download_path(path), "w") { |f| @dpla_db.view(view_name, options) { |row| f << csvify(filter(row)) } }
        FileUtils.mv download_path(path), path
      end
     end
    
  end

end