if [ -z "$SOLR_URL" ]; then
   echo "ERROR: no SOLR_URL defined"
   exit 1
fi

read -r -p "$SOLR_URL: ARE YOU SURE? [Y/n]? " response
case "$response" in 
  y|Y ) echo "Cleaning $SOLR_URL ..."
  ;;
  * ) exit 1
esac

for i in libra2; do

   url="$SOLR_URL/$i/update?stream.body=<delete><query>*:*</query></delete>&commit=true"
   curl "$url"

done

exit 0
