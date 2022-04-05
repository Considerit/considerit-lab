/////////
// Upload to s3 (and as a consequence, Cloudfront)

var s3 = require('s3'), 
    fs = require('fs');


config = require ('../config.json')

if (!config.aws) return // do nothing if aws isn't configured

var s3_client = s3.createClient({
    s3Options : {
      accessKeyId: config.aws.access_key_id,
      secretAccessKey: config.aws.secret_access_key,
    }})

// Syncs a directory from this host to s3. 
// set is_gzipped if you want to set the Content-Encoding to gzip for all
// files in this directory. 
var uploadDir = function(src, dest, is_gzipped) {

  s3_params = {
    Bucket: config.aws.s3_bucket,
    Prefix: dest,
    Expires: new Date(new Date().setYear(new Date().getFullYear() + 1)),
    CacheControl: 'public, max-age=31557600'
  }

  if (is_gzipped)
    s3_params.ContentEncoding = 'gzip'

  var uploader = s3_client.uploadDir({
    localDir: src,
    deleteRemoved: false, // remove s3 objects that lack 
                          // a corresponding config file. 
    s3Params: s3_params
  })

  uploader.on('error', function(err) {
    console.error("unable to sync:", err.stack)
  })
  uploader.on('end', function() {
    console.log("done uploading")
  })
  uploader.on('fileUploadEnd', function(path, key) {
    console.log("UPLOADED ", path)
  })
}

// sync static files
uploadDir( config.appDir + '/static', 'static')
