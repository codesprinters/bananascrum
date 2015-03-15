/* 
 * JS code for the registration forms
 */

bs.registration = {}

bs.registration.toggleCompanyFields = function() {
  var companyChecked = $("#customer_company:checked").length;
  if (companyChecked) {
    $(".company-fields").show();
    $(".non-company-fields").hide();
  } else {
    $(".non-company-fields").show();
    $(".company-fields").hide();
  }
  return true;
}

jQuery(document).ready(function() {
  jQuery('#customer_company').live('click', bs.registration.toggleCompanyFields);
  bs.registration.toggleCompanyFields();
});


