SET FOREIGN_KEY_CHECKS=0;

ALTER TABLE openmrs.person ADD COLUMN ptn_pk int (10);

-- First copy patient demographic data
-- Subject to changes to minimize data inconcistencey
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
	UNION SELECT person_id, IF(!ISNULL(`Patient Phone Plain`), `Patient Phone Plain`, ''), 8, 1, date_created, UUID() 
	FROM openmrs.person a INNER JOIN iqcare.rpt_patientdemographics b on a.ptn_pk=b.ptn_pk
	UNION SELECT person_id, IF(!ISNULL(`EmergContactName`), `EmergContactName`, ''), 11, 1, date_created, UUID() FROM openmrs.person a INNER JOIN iqcare.mst_patient b on a.ptn_pk=b.ptn_pk
	LEFT JOIN iqcare.dtl_patientcontacts d ON b.ptn_pk=d.ptn_pk
	UNION SELECT person_id, IF(!ISNULL(`EmergencyContactRelation`), `EmergencyContactRelation`, ''), 12, 1, date_created, UUID() FROM openmrs.person a INNER JOIN iqcare.mst_patient b on a.ptn_pk=b.ptn_pk
	LEFT JOIN iqcare.dtl_patientcontacts d ON b.ptn_pk=d.ptn_pk
	LEFT JOIN iqcare.rpt_emergencycontactrelation e ON d.EmergContactRelation=e.id
	UNION SELECT person_id, IF(!ISNULL(`EmergContactPhone`), `EmergContactPhone`, ''), 13, 1, date_created, UUID() FROM openmrs.person a INNER JOIN iqcare.mst_patient b on a.ptn_pk=b.ptn_pk
	LEFT JOIN iqcare.dtl_patientcontacts d ON b.ptn_pk=d.ptn_pk
	UNION SELECT person_id, IF(!ISNULL(`EmergContactAddress`), `EmergContactAddress`, ''), 14, 1, date_created, UUID() FROM openmrs.person a INNER JOIN iqcare.mst_patient b on a.ptn_pk=b.ptn_pk
	LEFT JOIN iqcare.dtl_patientcontacts d ON b.ptn_pk=d.ptn_pk;
	
INSERT INTO openmrs.obs(person_id, concept_id, obs_datetime, location_id, value_coded, creator, date_created, uuid)
	SELECT DISTINCT patient_id, 1054, b.date_created, location_id, IF(`value`='', NULL, `value`), 1, b.date_created, UUID() 
	FROM openmrs.visit a INNER JOIN 
	(SELECT `value`, person_id, date_created FROM openmrs.person_attribute WHERE person_attribute_type_id = 5) b 
	ON a.patient_id=b.person_id;
	
INSERT INTO openmrs.patient(patient_id, creator, date_created)
	SELECT person_id, IF(!ISNULL(creator), creator, 0), date_created FROM openmrs.person WHERE ptn_pk > 0;
	
INSERT INTO openmrs.patient_identifier(patient_id, identifier, identifier_type, location_id, creator, date_created, uuid)
	SELECT patient_id, IF(!ISNULL(HTSID), HTSID, ''), 4, location_id, 1, a.date_created, UUID() FROM openmrs.patient a 
    INNER JOIN openmrs.person b ON a.patient_id=b.person_id
	INNER JOIN iqcare.mst_patient c ON b.ptn_pk=c.ptn_pk
	LEFT JOIN iqcare.mst_facility d ON c.LocationID=d.FacilityID
	LEFT JOIN openmrs.location e ON d.FacilityName=e.name
    
	UNION SELECT patient_id, IF(!ISNULL(IdentifierValue), IdentifierValue, ''), 7, location_id, 1, a.date_created, UUID() 
    FROM openmrs.patient a 
    INNER JOIN openmrs.person b ON a.patient_id=b.person_id
	INNER JOIN iqcare.patient c ON b.ptn_pk=c.ptn_pk
	INNER JOIN iqcare.patientidentifier d ON c.id=d.patientid
    INNER JOIN iqcare.mst_patient e ON b.ptn_pk=e.ptn_pk
	LEFT JOIN iqcare.mst_facility f ON e.LocationID=f.FacilityID
	LEFT JOIN openmrs.location g ON f.FacilityName=g.name
    
	UNION SELECT patient_id, IF(!ISNULL(HEIIDNumber), HEIIDNumber, ''), 13, location_id, 1, a.date_created, UUID() 
    FROM openmrs.patient a INNER JOIN openmrs.person b ON a.patient_id=b.person_id
	INNER JOIN iqcare.mst_patient c ON b.ptn_pk=c.ptn_pk
	LEFT JOIN iqcare.mst_facility d ON c.LocationID=d.FacilityID
	LEFT JOIN openmrs.location e ON d.FacilityName=e.name;
	
INSERT INTO openmrs.person_name(person_id, given_name, middle_name, family_name, creator, date_created, uuid)
	SELECT person_id, `Patient First Name`, IF(`Patient Middle Name`='LName', '', `Patient Middle Name`), `Patient Last Name`, 1, a.date_created, UUID()
	FROM openmrs.person a INNER JOIN iqcare.rpt_patientdemographics b ON a.ptn_pk=b.ptn_pk;
	
-- End of Patient demographic data

-- Populating Patient Program
INSERT INTO openmrs.patient_program(patient_id, program_id, date_enrolled, creator, date_created, uuid)
	SELECT patient_id, 2, `Enrollment Date`, 1, CreateDate, UUID()
	FROM openmrs.patient a
	INNER JOIN  openmrs.person b ON a.patient_id=b.person_id
	LEFT JOIN iqcare.rpt_patient c ON b.ptn_pk=c.ptn_pk
	LEFT JOIN iqcare.mst_patient d ON b.ptn_pk=d.ptn_pk
	WHERE b.ptn_pk > 0;
-- End of Patient Program

-- Populating Patient Visit
INSERT INTO openmrs.visit_type(`name`, creator, date_created, uuid)
	SELECT `Visit Type`, 1, NOW(), UUID() FROM iqcare.rpt_visittype;
	
INSERT INTO openmrs.visit(patient_id, visit_type_id, date_started, date_stopped, creator, date_created, uuid)
	SELECT person_id, IF(!ISNULL(visit_type_id), visit_type_id, 1), VisitDate, ADDTIME(VisitDate, '02:00:00'), 1, c.CreateDate, UUID()
	FROM openmrs.person a
	INNER JOIN iqcare.dtl_patientvitals b ON a.ptn_pk=b.ptn_pk
	INNER JOIN iqcare.ord_visit c ON b.visit_pk=c.visit_id
	INNER JOIN iqcare.rpt_visittype d ON c.VisitType=d.VisitTypeID
	INNER JOIN openmrs.visit_type e ON d.`Visit Type`=e.`name`;
	
UPDATE openmrs.visit AS a, openmrs.patient_identifier AS b 
SET a.location_id = b.location_id
WHERE b.patient_id = a.patient_id;
-- End of Patient Visit	

-- Tackling Obs
-- #1 Patient Vitals
INSERT INTO openmrs.encounter(encounter_type, patient_id, location_id, form_id, encounter_datetime, creator, date_created, visit_id, uuid)
	SELECT 7, patient_id, location_id, 9, date_started, 1, date_created, visit_id, UUID() FROM openmrs.visit;
	
INSERT INTO openmrs.obs(person_id, concept_id, encounter_id, obs_datetime, location_id, value_numeric, creator, date_created, uuid)
	SELECT patient_id, 5088, encounter_id, date_created, location_id, temp, 1, date_created, UUID() 
	FROM iqcare.ord_visit a 
	INNER JOIN iqcare.dtl_patientvitals b ON a.visit_id=b.visit_pk
	INNER JOIN 
	(SELECT DISTINCTROW ptn_pk, patient_id, b.date_created, encounter_id, encounter_datetime, location_id 
	FROM openmrs.person a 
	INNER JOIN openmrs.encounter b ON a.person_id=b.patient_id WHERE !ISNULL(ptn_pk) AND !ISNULL(encounter_id)) c 
	ON a.ptn_pk=c.ptn_pk AND a.VisitDate=c.encounter_datetime
	WHERE !ISNULL(temp);
-- End of Obs

ALTER TABLE openmrs.person DROP COLUMN ptn_pk;

SET FOREIGN_KEY_CHECKS=1;