# Copies one graph to another
#
# URL VARIABLES
# - task_uuid:
#   The UUID of the task which contains the copy information.
#
# ENV VARIABLES
# - COPY_CHECK: ASK SPARQL Query which will be executed to decide
#   whether or not the copy task may be executed.
# - SPARQL_<NAME>_ENDPOINT: Should contain the endpoint for the
#   short name which is described in the triplestore.
post '/copy/:task_uuid' do
  content_type 'application/json'

  # Check if we can copy
  if ENV['COPY_CHECK']
    unless query ENV['COPY_CHECK'].gsub('COPY_TASK_UUID', params['task_uuid'].sparql_escape)
      error "Graph copy checks did not pass."
    end
  end

  # Retrieve base info on sparql query
  query_result = query <<SPARQL
    SELECT ?source_graph ?target_graph ?source_endpoint ?target_endpoint WHERE {
      GRAPH <http://mu.semte.ch/application> {
        ?graphObject <http://mu.semte.ch/vocabularies/core/uuid> #{params['task_uuid'].sparql_escape};
           <http://mu.semte.ch/vocabularies/core/source_graph> ?source_graph;
           <http://mu.semte.ch/vocabularies/core/source_endpoint> ?source_endpoint;
           <http://mu.semte.ch/vocabularies/core/target_graph> ?target_graph;
           <http://mu.semte.ch/vocabularies/core/target_endpoint> ?target_endpoint.
      }
    }
SPARQL
  info = query_result.first

  # Make endpoints based on specs
  if info['source_endpoint'] == "default"
    source_endpoint = settings.sparql_client
  else
    source_endpoint = SPARQL::Client.new(ENV["SPARQL_#{info['source_endpoint'].to_s.upcase}_ENDPOINT"])
  end

  if info['target_endpoint'] == "default"
    target_endpoint = settings.sparql_client
  else
    target_endpoint = SPARQL::Client.new(ENV["SPARQL_#{info['target_endpoint'].to_s.upcase}_ENDPOINT"])
  end

  # Transfer all statements
  statements = source_endpoint.query <<SPARQL
    CONSTRUCT {
      ?s ?p ?o.
    } WHERE {
      GRAPH <#{info['source_graph']}> {
        ?s ?p ?o.
      }
    }
SPARQL
  materialized_statements = statements.map { |s| s }
  insert_query = target_endpoint.insert_data(materialized_statements, :graph => info['target_graph'])

  # Write out changes
  update <<SPARQL
    WITH <http://mu.semte.ch/application>
    DELETE {
      ?copyTask <http://mu.semte.ch/vocabularies/core/status> ?status.
    }
    INSERT {
      ?copyTask <http://mu.semte.ch/vocabularies/core/status> "done".
    }
    WHERE {
      ?copyTask <http://mu.semte.ch/vocabularies/core/uuid> #{params['task_uuid'].sparql_escape};
                <http://mu.semte.ch/vocabularies/core/status> ?status.
    }
SPARQL

  # Write out information
  { data: { attributes: { status: "executed" } } }.to_json
end
