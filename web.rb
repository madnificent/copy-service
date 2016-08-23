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
post '/copy/' do
  content_type 'application/json'

  update <<SPARQL
    INSERT {
      GRAPH <#{params["target_graph"]}> {
        ?s ?p ?o.
      }
    }
    WHERE {
      GRAPH <#{params["source_graph"]}> {
        ?s ?p ?o.
      }
    }
SPARQL

  { data: { attributes: { status: "executed" } } }.to_json
end
