RUBY_GC_HEAP_INIT_SLOTS=600000
RUBY_GC_HEAP_FREE_SLOTS=200000
RUBY_GC_MALLOC_LIMIT=60000000
export RUBY_GC_HEAP_INIT_SLOTS RUBY_FREE_MIN RUBY_GC_MALLOC_LIMIT

pid="log/pic.pid"

case "$1" in
  start)
    nohup bundle exec rake download &
    ;;
  stop)
    kill -INT `cat $pid`
    ;;
  *)
  ;;
esac
