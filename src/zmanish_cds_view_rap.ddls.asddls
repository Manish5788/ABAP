@AbapCatalog.sqlViewName: 'ZMANISH_CDS_VI'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@EndUserText.label: 'RAP CDS MANISH'
define view ZMANISH_CDS_VIEW_RAP
  as select from /dmo/customer as SO

{


  key SO.customer_id           as CustomerId,
      SO.first_name            as FirstName,
      SO.last_name             as LastName,
      SO.title                 as Title,
      SO.street                as Street,
      SO.postal_code           as PostalCode,
      SO.city                  as City,
      SO.country_code          as CountryCode,
      SO.phone_number          as PhoneNumber,
      SO.email_address         as EmailAddress,
      SO.local_created_by      as LocalCreatedBy,
      SO.local_created_at      as LocalCreatedAt,
      SO.local_last_changed_by as LocalLastChangedBy,
      SO.local_last_changed_at as LocalLastChangedAt,
      SO.last_changed_at       as LastChangedAt

}
