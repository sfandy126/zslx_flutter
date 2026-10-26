import 'md_env.dart';

enum MDCmd {
  // v2
  thirdLogin('zs_third_login', 'third_login'),
  bindThird('zs_bind_third', 'new_bind_third'),
  bindMobile('zs_bind_mobile', 'bind_mobile'),
  bindGuest('zs_bind_guest', 'bind_mobile_yk'),
  thirdSiqt('zs_third_siqt', 'third_login_siqt'),
  popUp('zs_pop_up', 'pop_up'),
  remind('zs_remind', 'remind'),
  popUpReport('zs_pop_up_report', 'pop_up_close'),
  remindReport('zs_remind_report', 'add_pop_up_two'),
  videoDurationReport('zs_video_duration_report', 'course_lb_schedule'),
  checkCourse('zs_check_course', 'check_course'),
  oss('zs_oss', 'oss'),
  zyList('zs_zy_list', 'course_zy_list'),
  zyLog('zs_zy_log', 'zy_list'),
  zyPublic('zs_zy_public', 'my_zy_show'),
  zySubmit('zs_zy_submit', 'zy_submit_new'),

  // v1
  courseIosOrders('zs_course_orders', 'course_dj_list'),
  courseOrders('zs_mine_order', 'new_my_order'),
  courseOrderConfirm('zs_confirm_order', 'course_confirm_order'),
  courseGenerateOrder('zs_generate_order', 'course_generate_order'),
  courseOrderJump('zs_order_jump', 'course_order_jump'),
  coursePayment('zs_payment', 'course_payment'),
  courseGetPay('zs_pay_mthod', 'get_pay'),
  courseDelOrder('zs_delete_order', 'del_order'),
  courseOrderFakeDel('zs_fake_order', 'order_fake_del'),

  memberInfo('zs_member_info', 'member_info'),
  login('zs_login', 'login_v2'),
  courseDetail('zs_course_detail', 'course_detail'),
  myCourses('zs_my_courses', 'new_my_course'),
  home('zs_home', 'up_new_home_v2'),
  sendCode('zs_send_code', 'send_sms_code'),
  forgotPwd('zs_forgot_pwd', 'forgot_pwd'),
  loginGuest('zs_login_guest', 'login_yk'),
  version('zs_version', 'check_ver'),
  modifyNick('zs_modify_nick', 'my_nickname'),
  modifyAvatar('zs_modify_avatar', 'my_avatar'),
  logout('zs_logout', 'logout'),
  modifyPwd('zs_modify_pwd', 'my_pwd'),
  logoff('zs_logoff', 'account_off'),
  collects('zs_collects', 'collection_list'),
  feedback('zs_feedback', 'feedback'),
  iapProducts('zs_iap_products', 'recharge_products'),
  iapOrders('zs_iap_orders', 'iap_money_log_list'),
  iapCreateOrder('zs_iap_create_order', 'create_recharge_order'),
  iapVerifyOrder('zs_iap_verify_order', 'iap_order'),
  courseList('zs_course_list', 'course_list_new'),
  dateCourses('zs_date_courses', 'my_appointment'),
  cancelYdy('zs_cancel_ydy', 'cancel_appointment'),
  prebokYdy('zs_prebok_ydy', 'ydy_appointment'),
  monthDate('zs_month_date', 'my_appointment_date'),
  joinGk('zs_join_gk', 'gk_add'),
  ossUrl('zs_oss_url', 'update_oss_url'),
  courseFiles('zs_course_files', 'course_file_list'),
  courseFavorite('zs_course_favorite', 'add_course_collection'),
  courseConfirmIos('zs_course_confirm_ios', 'kc_confirm'),
  coursPay('zs_cours_pay', 'cours_pay'),
  playback('zs_playback', 'get_hf_data'),
  live('zs_live', 'get_live_data');

  const MDCmd(this.zsValue, this.otherValue);

  final String zsValue;

  final String otherValue;

  String get value => MDEnv.isZslx ? zsValue : otherValue;
}
