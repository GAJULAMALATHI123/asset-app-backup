namespace asset.lifecycle.db;
using { cuid,managed } from '@sap/cds/common';
using { asset.lifecycle.db.EmployeeStatus, asset.lifecycle.db.AssetStatus, asset.lifecycle.db.AssignmentStatus, asset.lifecycle.db.LedgerAction, asset.lifecycle.db.MaintenanceType,
        asset.lifecycle.db.MaintenanceStatus, asset.lifecycle.db.MaintenanceOutcome, asset.lifecycle.db.ArchiveReason, asset.lifecycle.db.DisposalMethod, asset.lifecycle.db.AssetRequestStatus } from './types';

entity Department : managed {
  key dept_id : UUID;
  name        : String(80) @mandatory   @title : '{i18n>DEPARTMENT_NAME}';
  cost_center : String(20)  @title : '{i18n>COST_CENTER}';
  is_active   : Boolean default true 
  @title : '{i18n>ACTIVE_STATUS}';                       // FR-027: deactivate instead of delete
  employees   : Association to many Employee on employees.department = $self;
}
entity Employee : managed {
  key employee_id : UUID;
  full_name  : String(100) @mandatory    @title : '{i18n>Employee Name}';
  email      : String(100) @title : '{i18n>EMAIL}';
  phone      : String(20) @title : '{i18n>PHONE}';
  department : Association to Department;
  location   : String(100) @title : '{i18n>LOCATION}';
  status     : EmployeeStatus default #ACTIVE @title : '{i18n>STATUS}';
  assets              : Association to many Asset on assets.current_holder = $self;
  reportedMaintenance : Association to many MaintenanceRecord on reportedMaintenance.reported_by = $self;
  assignments         : Association to many AssetAssignment on assignments.employee = $self;
}
entity AssetCategory : managed {
  key asset_category_id : UUID;
  name            : String(50) @mandatory  @title : '{i18n>CATEGORY_NAME}';
  lifespan_months : Integer @title : '{i18n>LIFESPAN_MONTHS}';
  is_active       : Boolean default true   @title : '{i18n>ACTIVE_STATUS}';
  assets          : Association to many Asset on assets.assetCategory = $self;
}
entity Vendor : managed {
  key vendor_id : UUID;
  name      : String(100) @mandatory  @title : '{i18n>VENDOR_NAME}';
  email     : String(100)  @title : '{i18n>EMAIL}';
  is_active : Boolean default true @title : '{i18n>ACTIVE_STATUS}';
  suppliedAssets     : Association to many Asset on suppliedAssets.vendor = $self;
  maintenanceRecords : Association to many MaintenanceRecord on maintenanceRecords.service_vendor = $self;
}
@assert.unique: { tag: [asset_tag], serial: [serial_number] }   // FR-001
entity Asset : managed {
  key asset_id : UUID  @title : '{i18n>ASSET_TAG}';
  asset_tag     : String(20) @mandatory @title : '{i18n>SERIAL_NUMBER}';
  serial_number : String(50) @mandatory;
  assetCategory : Association to AssetCategory @mandatory;
  vendor        : Association to Vendor;
  model         : String(100)  @title : '{i18n>MODEL}';
  location      : String(100)   @title : '{i18n>LOCATION}';
  purchase_date : Date not null @title : '{i18n>PURCHASE_DATE}';
  purchase_cost : Decimal(10,2) @title : '{i18n>PURCHASE_COST}';
  warranty_expiry         : Date @title : '{i18n>WARRANTY_EXPIRY}';
  first_distribution_date : Date   @title : '{i18n>FIRST_DISTRIBUTION_DATE}';
  status         : AssetStatus default #AVAILABLE  @title : '{i18n>STATUS}';
  current_holder : Association to Employee;
  retirement_reason : String(255) @title : '{i18n>RETIREMENT_REASON}';
  retirement_date   : Date  @title : '{i18n>RETIREMENT_DATE}';
  assignments        : Composition of many AssetAssignment  on assignments.asset = $self;
  ownershipHistory   : Composition of many OwnershipLedger  on ownershipHistory.asset = $self;
  maintenanceRecords : Composition of many MaintenanceRecord on maintenanceRecords.asset = $self;
  archiveRecords     : Composition of many ArchiveRecord    on archiveRecords.asset = $self;
}
entity AssetAssignment : managed {
  key assignment_id : UUID;
  asset      : Association to Asset;
  employee   : Association to Employee;
  assigned_by          : String(100) @title : '{i18n>ASSIGNED_BY}';                     // XSUAA user id
  assigned_date        : Date  @title : '{i18n>ASSIGNED_DATE}';
  expected_return_date : Date  @title : '{i18n>EXPECTED_RETURN_DATE}';
  actual_return_date   : Date   @title : '{i18n>ACTUAL_RETURN_DATE}';
  assignment_status    : AssignmentStatus   @title : '{i18n>ASSIGNMENT_STATUS}';
  remarks              : LargeString   @title : '{i18n>REMARKS}';
}
entity OwnershipLedger : managed {                          // immutable (FR-007)
  key ledger_id : UUID;
  asset         : Association to Asset;
  from_employee : Association to Employee;
  to_employee   : Association to Employee;
  action        : LedgerAction  @title : '{i18n>ACTION}';
  transition_date : Date  @title : '{i18n>TRANSITION_DATE}';
  recorded_by   : String(100) @title : '{i18n>RECORDED_BY}';
  notes         : LargeString  @title : '{i18n>NOTES}';
}
entity MaintenanceRecord : managed {
  key maintenance_id : UUID;
  asset          : Association to Asset;
  type           : MaintenanceType  @title : '{i18n>MAINTENANCE_TYPE}';
  reported_by    : Association to Employee;
  service_vendor : Association to Vendor;
  reported_date  : Date  @title : '{i18n>REPORTED_DATE}';
  completed_date : Date   @title : '{i18n>COMPLETED_DATE}';
  status         : MaintenanceStatus @title : '{i18n>STATUS}';
  outcome        : MaintenanceOutcome @title : '{i18n>OUTCOME}';
  cost           : Decimal(10,2)  @title : '{i18n>COST}';
  covered_by_warranty : Boolean   @title : '{i18n>COVERED_BY_WARRANTY}';
  next_due_date  : Date @title : '{i18n>NEXT_DUE_DATE}';
  description    : LargeString @title : '{i18n>DESCRIPTION}';
}
entity ArchiveRecord : managed {
  key archive_id : UUID;
  asset            : Association to Asset;
  archived_at      : Timestamp @title : '{i18n>ARCHIVED_AT}';
  archived_by      : String(100) @title : '{i18n>ARCHIVED_BY}';
  reason           : ArchiveReason  @title : '{i18n>REASON}';
  disposal_method  : DisposalMethod   @title : '{i18n>DISPOSAL_METHOD}';
  disposal_cert_no : String(40)   @title : '{i18n>DISPOSAL_CERT_NO}';
  compliance_ref   : String(60) @title : '{i18n>COMPLIANCE_REFERENCE}';
}

entity AssetRequest : managed {
  key request_id : UUID;
  requested_by : String(100) @mandatory @title : '{i18n>REQUESTED_BY}';
  employee : Association to Employee @mandatory;
  category : Association to AssetCategory @mandatory;
  reason : LargeString @mandatory  @title : '{i18n>REASON}';
  status : AssetRequestStatus default #PENDING @title : '{i18n>STATUS}';
  reviewed_by : String(100)  @title : '{i18n>REVIEWED_BY}' ;
  reviewed_at : Timestamp @title : '{i18n>REVIEWED_AT}';
  review_notes : LargeString @title : '{i18n>REVIEW_NOTES}';
  fulfilled_asset : Association to Asset;
}

entity ReportLog : cuid, managed {
  action     : String(20);     // PDF_DOWNLOAD | EMAIL
  filterText : String(1000);   // the filters that were applied
  recipient  : String(120);
  rowCount   : Integer;
  outcome    : String(20);     // OK | FAILED
  message    : String(300);
}
