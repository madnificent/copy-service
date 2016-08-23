# see https://github.com/mu-semtech/mu-ruby-template for more info
get '/' do
  content_type 'application/json'
  { data: { attributes: { hello: 'world' } } }.to_json
end


# Copies one graph to another
#
# Query parameters:
# - source_graph: The graph to copy contents from
# - target_graph: The graph to copy contents to
post '/copy/:task_uuid' do
  content_type 'application/json'

  if ENV['COPY_CHECK']
    unless query ENV['COPY_CHECK'].gsub('COPY_TASK_UUID', params['task_uuid'].sparql_escape)
      error "Graph copy checks did not pass."
    end
  end

  update <<SPARQL
    INSERT {
      GRAPH ?targetGraph {
        ?s ?p ?o.
      }
    }
    WHERE {
      GRAPH <http://mu.semte.ch/application> {
        ?graphObject <http://mu.semte.ch/vocabularies/core/uuid> #{params['task_uuid'].sparql_escape};
           <http://mu.semte.ch/vocabularies/core/source_graph> ?sourceGraph;
           <http://mu.semte.ch/vocabularies/core/target_graph> ?targetGraph.
      }
      GRAPH ?sourceGraph {
        ?s ?p ?o.
      }
    }
SPARQL

  { data: { attributes: { status: "executed" } } }.to_json
end
