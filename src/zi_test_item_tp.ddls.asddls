@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Value Help Item Type'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_TEST_ITEM_TP as select from ztest_rap_itm_tp
{
    key item_type_id   as ItemTypeID,
    @Semantics.text: true
    type_name          as ItemName    
}
