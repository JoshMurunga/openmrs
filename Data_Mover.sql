SET FOREIGN_KEY_CHECKS=0;

ALTER TABLE openmrs.person ADD COLUMN ptn_pk int (10);

-- First copy patient demographic data
INSERT INTO openmrs.person(gender, birthdate, creator, date_created, uuid, ptn_pk)
	SELECT IF(Sex=16, 'M', 'F'), DOB, 1, CreateDate, UUID(), ptn_pk FROM iqcare.mst_patient;
	
INSERT INTO openmrs.person_address(person_id, city_village, state_province, creator, date_created, county_district, uuid)
	SELECT person_id, c.name, d.name, 1, date_created, e.name, UUID() FROM openmrs.person a INNER JOIN iqcare.mst_patient b ON a.ptn_pk=b.ptn_pk
	LEFT JOIN iqcare.mst_village c ON b.villagename=c.id 
    LEFT JOIN iqcare.mst_province d ON b.province=d.id 
    LEFT JOIN iqcare.mst_district e ON b.districtname=e.id;
	
INSERT INTO openmrs.person_attribute(person_id, `value`, person_attribute_type_id, creator, date_created, uuid)
	SELECT person_id, 
	IF(`Marital Status`='Single', 1059, 
	IF(`Marital Status`='Married', 5555, 
	IF(`Marital Status`='Divorced/separated', 163007, 
	IF(`Marital Status`='Other', 5622, 
	IF(`Marital Status`='Widowed', 1059, 
	IF(`Marital Status`='Cohabiting', 1060,
	IF(`Marital Status`='Cohabitating', 1060, 
	IF(`Marital Status`='Married Polygamous', 159715, 
	IF(`Marital Status`='Married Monogamous', 5555, 
	IF(`Marital Status`='MSM', 160578, '')))))))))), 5, 1, date_created, UUID()FROM openmrs.person a INNER JOIN iqcare.mst_patient b on a.ptn_pk=b.ptn_pk
	LEFT JOIN iqcare.rpt_maritalstatus c ON b.maritalstatus=c.id
	UNION SELECT person_id, IF(!ISNULL(`EmergContactName`), `EmergContactName`, ''), 11, 1, date_created, UUID() FROM openmrs.person a INNER JOIN iqcare.mst_patient b on a.ptn_pk=b.ptn_pk
	LEFT JOIN iqcare.dtl_patientcontacts d ON b.ptn_pk=d.ptn_pk
	UNION SELECT person_id, IF(!ISNULL(`EmergencyContactRelation`), `EmergencyContactRelation`, ''), 12, 1, date_created, UUID() FROM openmrs.person a INNER JOIN iqcare.mst_patient b on a.ptn_pk=b.ptn_pk
	LEFT JOIN iqcare.dtl_patientcontacts d ON b.ptn_pk=d.ptn_pk
	LEFT JOIN iqcare.rpt_emergencycontactrelation e ON d.EmergContactRelation=e.id
	UNION SELECT person_id, IF(!ISNULL(`EmergContactPhone`), `EmergContactPhone`, ''), 13, 1, date_created, UUID() FROM openmrs.person a INNER JOIN iqcare.mst_patient b on a.ptn_pk=b.ptn_pk
	LEFT JOIN iqcare.dtl_patientcontacts d ON b.ptn_pk=d.ptn_pk
	UNION SELECT person_id, IF(!ISNULL(`EmergContactAddress`), `EmergContactAddress`, ''), 14, 1, date_created, UUID() FROM openmrs.person a INNER JOIN iqcare.mst_patient b on a.ptn_pk=b.ptn_pk
	LEFT JOIN iqcare.dtl_patientcontacts d ON b.ptn_pk=d.ptn_pk;
	
INSERT INTO openmrs.patient(patient_id, creator, date_created)
	SELECT person_id, creator, date_created FROM openmrs.person;

ALTER TABLE openmrs.person DROP COLUMN ptn_pk;

SET FOREIGN_KEY_CHECKS=1;