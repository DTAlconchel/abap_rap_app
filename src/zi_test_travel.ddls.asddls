@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Value Help Travel'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_TEST_TRAVEL as select from ztest_rap_travel
{
    key travel_id   as TravelID,
    @Semantics.text: true
    travel_name as TravelName
}
