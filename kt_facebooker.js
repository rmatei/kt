function feedstory_send(url_prefix, uid, uuid, st1, st2)
{
  var img = document.createElement('img');

  var param_array = {
    'uid' : String(uid),
    'uuid' : String(uuid)
  };

  if( st1 != undefined )
  {
    param_array['st1'] = st1;
  }
  if( st2 != undefined )
  {
    param_array['st2'] = st2;
  }

  var query_str = http_build_query(param_array);
  img.src = url_prefix+'/ajax_kt_feedstory_send/?' + query_str;
}

function feedstory_send_vo(url_prefix, uid, uuid, campaign)
{
  var img = document.createElement('img');
  var abtest_data = JSON.parse(kt_getCookie(kt_feed_cookie_prefix+campaign));

  var param_array = {
    'uid' : String(uid),
    'uuid' : String(uuid)
  };

  param_array['st1'] = format_kt_st1(campaign, abtest_data['handle_index']);
  param_array['st2'] = format_kt_st2(abtest_data['data'][0]);
  param_array['st3'] = format_kt_st3(abtest_data['data'][0]);
  var query_str = http_build_query(param_array);
  alert(url_prefix + '/ajax_kt_feedstory_send/?' + query_str);//xxx
  img.src = url_prefix + '/ajax_kt_feedstory_send/?' + query_str;
}