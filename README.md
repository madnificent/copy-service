# Copy Service

Allows copying content from one graph or database to another, within a mu.semte.ch application.

This service could be used to make backups.  Documenting by example, as this is a short and simple service.  Note that the predicates used here should be changed.

## Simple Example
Add the copy-service to your docker-compose.yml.  Specify the `COPY_CHECK` if you want a check to be ran.

    copyservice:
      image: madnificent/copy-service
      links:
        - db:database
      environment:
        COPY_CHECK: "ASK { GRAPH <http://mu.semte.ch/application> { ?task <http://mu.semte.ch/vocabularies/core/uuid> COPY_TASK_UUID; <http://mu.semte.ch/vocabularies/core/status> \"waiting\". } }"

Add a task to the triplestore which can be executed:

    INSERT DATA {
      GRAPH <http://mu.semte.ch/application> {
        <http://mu.semte.ch/copy-tasks/4643942c-c1b6-40af-b567-7b8c8f6e11e1>
          <http://mu.semte.ch/vocabularies/core/uuid> "4643942c-c1b6-40af-b567-7b8c8f6e11e1";
          <http://mu.semte.ch/vocabularies/core/source_graph> <http://mu.semte.ch/application>;
          <http://mu.semte.ch/vocabularies/core/source_endpoint> "default";
          <http://mu.semte.ch/vocabularies/core/target_graph> <http://mu.semte.ch/tmp>;
          <http://mu.semte.ch/vocabularies/core/target_endpoint> "default;
          <http://mu.semte.ch/vocabularies/core/status> "waiting".
      }
    }

Execute the task by sending a `POST` request to `/copy/4643942c-c1b6-40af-b567-7b8c8f6e11e1`.  If copying was allowed, the response should be `{ data: { attributes: { status: "executed" } } }`.

The task will have the status `"done"` at the end of the execution.


## Extensive Example
Assuming you have two databases in your application, you can write from one database to the other.  This example shows such use.

    copyservice:
      image: madnificent/copy-service
      links:
        - db:database
        - backupdb:backupdb
      environment:
        SPARQL_BACKUP_ENDPOINT: "http://backupdb:8890/sparql"
        COPY_CHECK: "ASK { GRAPH <http://mu.semte.ch/application> { ?task <http://mu.semte.ch/vocabularies/core/uuid> COPY_TASK_UUID; <http://mu.semte.ch/vocabularies/core/status> \"waiting\". } }"

This approach requires you to add a link in your docker-compose.yml, so we can access the second database.  It also requires you to set the sparql endpoint of the backup database.  The environment variable bases itself on the name of the sparql endpoint as specified in the triplestore.  For the name `backup`, the environment variable would become `SPARQL_BACKUP_ENDPOINT`.

The task to be executed will now contain the `backup` database as a target.

    INSERT DATA {
      GRAPH <http://mu.semte.ch/application> {
        <http://mu.semte.ch/copy-tasks/82946317-7bf8-409b-bb50-3d6aee1859b5>
          <http://mu.semte.ch/vocabularies/core/uuid> "82946317-7bf8-409b-bb50-3d6aee1859b5";
          <http://mu.semte.ch/vocabularies/core/source_graph> <http://mu.semte.ch/application>;
          <http://mu.semte.ch/vocabularies/core/source_endpoint> "default";
          <http://mu.semte.ch/vocabularies/core/target_graph> <http://mu.semte.ch/backups>;
          <http://mu.semte.ch/vocabularies/core/target_endpoint> "backup;
          <http://mu.semte.ch/vocabularies/core/status> "waiting".
      }
    }

The task will have the status `"done"` at the end of the execution.
