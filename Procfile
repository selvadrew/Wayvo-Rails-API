web: bin/rails server -p $PORT -e $RAILS_ENV
worker: env QUEUE=* TERM_CHILD=1 INTERVAL=0.1 RESQUE_PRE_SHUTDOWN_TIMEOUT=20 RESQUE_TERM_TIMEOUT=8 bundle exec rake resque:work
