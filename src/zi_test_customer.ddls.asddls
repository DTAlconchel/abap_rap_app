@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Value Help Customer'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_TEST_CUSTOMER as select from ztest_rap_cust
{
    key customer_id   as CustomerID,
    @Semantics.text: true
    customer_name as CustomerName
}
