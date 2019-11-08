SET FOREIGN_KEY_CHECKS=0;

ALTER TABLE openmrs.person ADD COLUMN ptn_pk int (10);

-- First copy patient demographic data
-- Subject to changes to minimize data inconcistencey
-- Consider also ptn_pks that are 0
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
	
DELETE FROM openmrs.person_attribute WHERE `value`='';
DELETE FROM openmrs.person_attribute WHERE `value`='NULL';
DELETE FROM openmrs.person_attribute WHERE `value`='N/A';
	
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
	
DELETE FROM openmrs.patient_identifier WHERE `identifier`='';
DELETE FROM openmrs.patient_identifier WHERE `identifier`='NULL';
DELETE FROM openmrs.patient_identifier WHERE `identifier`='N/A';	
	
INSERT INTO openmrs.person_name(person_id, given_name, middle_name, family_name, creator, date_created, uuid)
	SELECT person_id, `Patient First Name`, IF(`Patient Middle Name`='LName', '', `Patient Middle Name`), `Patient Last Name`, 1, a.date_created, UUID()
	FROM openmrs.person a INNER JOIN iqcare.rpt_patientdemographics b ON a.ptn_pk=b.ptn_pk;
	
-- End of Patient demographic data

-- Populating Patient Program
INSERT INTO openmrs.patient_program(patient_id, program_id, date_enrolled, creator, date_created, uuid)
	SELECT DISTINCT patient_id, 2, `Enrollment Date`, 1, CreateDate, UUID()
	FROM openmrs.patient a
	INNER JOIN  openmrs.person b ON a.patient_id=b.person_id
	LEFT JOIN iqcare.rpt_patient c ON b.ptn_pk=c.ptn_pk
	LEFT JOIN iqcare.mst_patient d ON b.ptn_pk=d.ptn_pk
	WHERE b.ptn_pk > 0;
-- End of Patient Program

-- Populating Patient Visit
ALTER TABLE openmrs.encounter ADD COLUMN visit_pk int (10);
ALTER TABLE openmrs.visit ADD COLUMN visit_pk int (10);

DELIMITER //
CREATE TRIGGER insert_into_encounter
AFTER INSERT
	ON openmrs.visit FOR EACH ROW
BEGIN
	INSERT INTO openmrs.encounter
	(encounter_type, patient_id, location_id, form_id, encounter_datetime, creator, date_created, visit_id, uuid, visit_pk)
	VALUES
	(7, NEW.patient_id, 2631, 9, NEW.date_started, 1, NEW.date_created, NEW.visit_id, UUID(), NEW.visit_pk);
END; //
DELIMITER ;

INSERT INTO openmrs.visit_type(`name`, creator, date_created, uuid)
	SELECT `Visit Type`, 1, NOW(), UUID() FROM iqcare.rpt_visittype;
	
INSERT INTO openmrs.visit(patient_id, visit_type_id, date_started, date_stopped, creator, date_created, uuid, visit_pk)
	SELECT person_id, IF(!ISNULL(visit_type_id), visit_type_id, 1), VisitDate, ADDTIME(VisitDate, '02:00:00'), 1, c.CreateDate, UUID(), visit_pk
	FROM openmrs.person a
	INNER JOIN iqcare.dtl_patientvitals b ON a.ptn_pk=b.ptn_pk
	INNER JOIN iqcare.ord_visit c ON b.visit_pk=c.visit_id
	INNER JOIN iqcare.rpt_visittype d ON c.VisitType=d.VisitTypeID
	INNER JOIN openmrs.visit_type e ON d.`Visit Type`=e.`name`;
	
INSERT INTO openmrs.visit(patient_id, visit_type_id, date_started, date_stopped, creator, date_created, uuid, visit_pk)
	SELECT person_id, IF(!ISNULL(visit_type_id), visit_type_id, 1), VisitDate, ADDTIME(VisitDate, '02:00:00'), 1, c.CreateDate, UUID(), c.visit_id
	FROM openmrs.person a
	INNER JOIN iqcare.ord_visit c ON a.ptn_pk=c.ptn_pk
	INNER JOIN iqcare.rpt_visittype d ON c.VisitType=d.VisitTypeID
	INNER JOIN openmrs.visit_type e ON d.`Visit Type`=e.`name`
	WHERE !ISNULL(VisitDate)
	AND c.Visit_Id NOT IN (SELECT visit_pk FROM openmrs.visit f INNER JOIN iqcare.ord_visit g ON f.visit_pk=g.Visit_Id);
	
INSERT INTO openmrs.visit(patient_id, visit_type_id, date_started, date_stopped, creator, date_created, uuid, visit_pk)
	SELECT person_id, 1, `start`, `end`, 1, d.createdate, UUID(), patientmastervisitid + 1000000
	FROM openmrs.person a
	INNER JOIN iqcare.patient b ON a.ptn_pk=b.ptn_pk
	INNER JOIN iqcare.patientvitals c ON b.id=c.patientid
	INNER JOIN iqcare.patientmastervisit d ON c.patientmastervisitid=d.id;
	
INSERT INTO openmrs.visit(patient_id, visit_type_id, date_started, date_stopped, creator, date_created, uuid, visit_pk)
	SELECT person_id, 1, visitdate, ADDTIME(VisitDate, '03:00:00'), 1, a.createdate, UUID(), patientmastervisitid + 1000000
	FROM iqcare.patientvitals a 
	INNER JOIN iqcare.patient b ON a.PatientId=b.id 
	INNER JOIN openmrs.person c ON b.ptn_pk=c.ptn_pk
	WHERE patientmastervisitid 
	NOT IN 
	(SELECT id FROM iqcare.patientmastervisit);
	
UPDATE openmrs.visit AS a, openmrs.patient_identifier AS b 
SET a.location_id = b.location_id
WHERE b.patient_id = a.patient_id;

DROP TRIGGER insert_into_encounter;
-- End of Patient Visit	

-- Tackling Obs
-- #1 Patient Civil Status
INSERT INTO openmrs.obs(person_id, concept_id, obs_datetime, location_id, value_coded, creator, date_created, uuid)
	SELECT DISTINCT patient_id, 1054, b.date_created, location_id, IF(`value`='', NULL, `value`), 1, b.date_created, UUID() 
	FROM openmrs.visit a INNER JOIN 
	(SELECT `value`, person_id, date_created FROM openmrs.person_attribute WHERE person_attribute_type_id = 5) b 
	ON a.patient_id=b.person_id;
	
-- #2 Patient temp
INSERT INTO openmrs.obs(person_id, concept_id, encounter_id, obs_datetime, location_id, value_numeric, creator, date_created, uuid)
	SELECT patient_id, 5088, encounter_id, date_created, location_id, temp, 1, date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.dtl_patientvitals b ON a.visit_pk=b.visit_pk
	WHERE !ISNULL(temp);
	
INSERT INTO openmrs.obs(person_id, concept_id, encounter_id, obs_datetime, location_id, value_numeric, creator, date_created, uuid)
	SELECT DISTINCT patient_id, 5088, encounter_id, date_created, location_id, temperature, 1, date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientvitals b ON a.visit_pk=b.patientmastervisitid + 1000000
	WHERE a.encounter_datetime=b.visitdate
	AND temperature<>0;
	
INSERT INTO openmrs.obs(person_id, concept_id, encounter_id, obs_datetime, location_id, value_numeric, creator, date_created, uuid)
	SELECT DISTINCT patient_id, 5088, encounter_id, date_created, location_id, temperature, 1, date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientvitals b ON a.visit_pk=b.patientmastervisitid + 1000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	WHERE a.encounter_datetime=c.`start`
	AND temperature<>0;
   
-- #3 Patient Blood Pressure (Diastolic) 
INSERT INTO openmrs.obs(person_id, concept_id, encounter_id, obs_datetime, location_id, value_numeric, creator, date_created, uuid)
	SELECT patient_id, 5086, encounter_id, date_created, location_id, BPDiastolic, 1, date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.dtl_patientvitals b ON a.visit_pk=b.visit_pk
	WHERE !ISNULL(BPDiastolic);
	
INSERT INTO openmrs.obs(person_id, concept_id, encounter_id, obs_datetime, location_id, value_numeric, creator, date_created, uuid)
	SELECT DISTINCT patient_id, 5086, encounter_id, date_created, location_id, BPDiastolic, 1, date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientvitals b ON a.visit_pk=b.patientmastervisitid + 1000000
	WHERE a.encounter_datetime=b.visitdate
	AND BPDiastolic<>0;
    
INSERT INTO openmrs.obs(person_id, concept_id, encounter_id, obs_datetime, location_id, value_numeric, creator, date_created, uuid)
	SELECT DISTINCT patient_id, 5086, encounter_id, date_created, location_id, BPDiastolic, 1, date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientvitals b ON a.visit_pk=b.patientmastervisitid + 1000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	WHERE a.encounter_datetime=c.`start`
	AND BPDiastolic<>0;
   
-- #4 Patient Blood Pressure (Systolic)
INSERT INTO openmrs.obs(person_id, concept_id, encounter_id, obs_datetime, location_id, value_numeric, creator, date_created, uuid)
	SELECT patient_id, 5085, encounter_id, date_created, location_id, BPSystolic, 1, date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.dtl_patientvitals b ON a.visit_pk=b.visit_pk
	WHERE !ISNULL(BPSystolic);
	
INSERT INTO openmrs.obs(person_id, concept_id, encounter_id, obs_datetime, location_id, value_numeric, creator, date_created, uuid)
	SELECT DISTINCT patient_id, 5085, encounter_id, date_created, location_id, BPSystolic, 1, date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientvitals b ON a.visit_pk=b.patientmastervisitid + 1000000
	WHERE a.encounter_datetime=b.visitdate
	AND BPSystolic<>0;
    
INSERT INTO openmrs.obs(person_id, concept_id, encounter_id, obs_datetime, location_id, value_numeric, creator, date_created, uuid)
	SELECT DISTINCT patient_id, 5085, encounter_id, date_created, location_id, BPSystolic, 1, date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientvitals b ON a.visit_pk=b.patientmastervisitid + 1000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	WHERE a.encounter_datetime=c.`start`
	AND BPSystolic<>0;
   
-- #5 Patient Height
INSERT INTO openmrs.obs(person_id, concept_id, encounter_id, obs_datetime, location_id, value_numeric, creator, date_created, uuid)
	SELECT patient_id, 5090, encounter_id, date_created, location_id, Height, 1, date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.dtl_patientvitals b ON a.visit_pk=b.visit_pk
	WHERE !ISNULL(Height);
	
INSERT INTO openmrs.obs(person_id, concept_id, encounter_id, obs_datetime, location_id, value_numeric, creator, date_created, uuid)
	SELECT DISTINCT patient_id, 5090, encounter_id, date_created, location_id, Height, 1, date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientvitals b ON a.visit_pk=b.patientmastervisitid + 1000000
	WHERE a.encounter_datetime=b.visitdate
	AND Height<>0;
    
INSERT INTO openmrs.obs(person_id, concept_id, encounter_id, obs_datetime, location_id, value_numeric, creator, date_created, uuid)
	SELECT DISTINCT patient_id, 5090, encounter_id, date_created, location_id, Height, 1, date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientvitals b ON a.visit_pk=b.patientmastervisitid + 1000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	WHERE a.encounter_datetime=c.`start`
	AND Height<>0;
   
-- #6 Patient Weight
INSERT INTO openmrs.obs(person_id, concept_id, encounter_id, obs_datetime, location_id, value_numeric, creator, date_created, uuid)
	SELECT patient_id, 5089, encounter_id, date_created, location_id, Weight, 1, date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.dtl_patientvitals b ON a.visit_pk=b.visit_pk
	WHERE !ISNULL(Weight);
	
INSERT INTO openmrs.obs(person_id, concept_id, encounter_id, obs_datetime, location_id, value_numeric, creator, date_created, uuid)
	SELECT DISTINCT patient_id, 5089, encounter_id, date_created, location_id, Weight, 1, date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientvitals b ON a.visit_pk=b.patientmastervisitid + 1000000
	WHERE a.encounter_datetime=b.visitdate
	AND Weight<>0;
    
INSERT INTO openmrs.obs(person_id, concept_id, encounter_id, obs_datetime, location_id, value_numeric, creator, date_created, uuid)
	SELECT DISTINCT patient_id, 5089, encounter_id, date_created, location_id, Weight, 1, date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientvitals b ON a.visit_pk=b.patientmastervisitid + 1000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	WHERE a.encounter_datetime=c.`start`
	AND Weight<>0;
	
-- ***** HIV Form 20 Encounter ****
INSERT INTO openmrs.encounter (encounter_type, patient_id, form_id, encounter_datetime, creator, date_created, uuid)
	SELECT DISTINCT 12, patient_id, 20, IFNULL(`Enrollment Date`, NOW()), 1, CreateDate, UUID()
	FROM openmrs.patient a
	INNER JOIN  openmrs.person b ON a.patient_id=b.person_id
	LEFT JOIN iqcare.rpt_patient c ON b.ptn_pk=c.ptn_pk
	LEFT JOIN iqcare.mst_patient d ON b.ptn_pk=d.ptn_pk
	WHERE b.ptn_pk > 0;
   
-- #7 Patient WHO Stage
INSERT INTO openmrs.obs(person_id, concept_id, encounter_id, obs_datetime, location_id, value_coded, creator, date_created, uuid)
	SELECT patient_id, 5356, encounter_id, date_created, location_id, 
	IF(c.`WHOStage`='T1', 1204, 
	IF(c.`WHOStage`='1', 1204, 
	IF(c.`WHOStage`='T2', 1205, 
	IF(c.`WHOStage`='2', 1205, 
	IF(c.`WHOStage`='T3', 1206, 
	IF(c.`WHOStage`='3', 1206, 
	IF(c.`WHOStage`='T4', 1207, 
	IF(c.`WHOStage`='4', 1207, NULL)))))))) WHO, 1, date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.dtl_patientstage b ON a.visit_pk=b.visit_pk
	INNER JOIN iqcare.rpt_whostage c ON b.whostage=c.id
	WHERE !ISNULL(c.`WHOStage`) AND c.`WHOStage`<>'0' AND c.`WHOStage`<>'';

-- #8 CD4 Count
INSERT INTO openmrs.obs(person_id, concept_id, encounter_id, obs_datetime, location_id, value_numeric, creator, date_created, uuid)
	SELECT patient_id, 5497, encounter_id, date_created, location_id, CD4here, 1, date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN
	(SELECT DISTINCT visit_id, IFNULL(`Most Recent CD4 - IE`, `CD4`) CD4here
	FROM iqcare.rpt_patienthivprevcareie WHERE !ISNULL(CD4))b ON a.visit_pk=b.visit_id;
	
INSERT INTO openmrs.obs(person_id, concept_id, encounter_id, obs_datetime, location_id, value_numeric, creator, date_created, uuid)
	SELECT patient_id, 5497, encounter_id, date_created, location_id, ResultValue, 1, date_created, UUID()
	FROM openmrs.encounter a 
	INNER JOIN 
	(SELECT ResultValue, VisitId 
	FROM iqcare.dtl_labordertestresult b 
	INNER JOIN iqcare.dtl_labordertest c ON b.LabOrderTestId=c.Id
	INNER JOIN iqcare.ord_laborder d ON c.LabOrderId=d.Id
	WHERE ParameterId=1 AND !ISNULL(ResultValue)) e
	ON a.visit_pk=e.VisitId;
	
--  #9 CD4 %
INSERT INTO openmrs.obs(person_id, concept_id, encounter_id, obs_datetime, location_id, value_numeric, creator, date_created, uuid)
	SELECT patient_id, 730, encounter_id, date_created, location_id, ResultValue, 1, date_created, UUID()
	FROM openmrs.encounter a 
	INNER JOIN 
	(SELECT ResultValue, VisitId 
	FROM iqcare.dtl_labordertestresult b 
	INNER JOIN iqcare.dtl_labordertest c ON b.LabOrderTestId=c.Id
	INNER JOIN iqcare.ord_laborder d ON c.LabOrderId=d.Id
	WHERE ParameterId=2 AND !ISNULL(ResultValue)) e
	ON a.visit_pk=e.VisitId;

-- #10 Last Viral Load
INSERT INTO openmrs.obs(person_id, concept_id, encounter_id, obs_datetime, location_id, value_numeric, creator, date_created, uuid)
	SELECT patient_id, 856, encounter_id, date_created, location_id, `Most Recent Viral Load - IE`, 1, date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN
	(SELECT DISTINCT visit_id, `Most Recent Viral Load - IE`
	FROM iqcare.rpt_patienthivprevcareie WHERE !ISNULL(`Most Recent Viral Load - IE`))b ON a.visit_pk=b.visit_id;
	
INSERT INTO openmrs.obs(person_id, concept_id, encounter_id, obs_datetime, location_id, value_numeric, creator, date_created, uuid)
	SELECT patient_id, 856, encounter_id, date_created, location_id, ResultValue, 1, date_created, UUID()
	FROM openmrs.encounter a 
	INNER JOIN 
	(SELECT ResultValue, VisitId 
	FROM iqcare.dtl_labordertestresult b 
	INNER JOIN iqcare.dtl_labordertest c ON b.LabOrderTestId=c.Id
	INNER JOIN iqcare.ord_laborder d ON c.LabOrderId=d.Id
	WHERE ParameterId=3 AND !ISNULL(ResultValue)) e
	ON a.visit_pk=e.VisitId;
	
-- #11 Respiratory Rate
INSERT INTO openmrs.obs(person_id, concept_id, encounter_id, obs_datetime, location_id, value_numeric, creator, date_created, uuid)
	SELECT patient_id, 5242, encounter_id, date_created, location_id, RR, 1, date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.dtl_patientvitals b ON a.visit_pk=b.visit_pk
	WHERE !ISNULL(RR);
	
INSERT INTO openmrs.obs(person_id, concept_id, encounter_id, obs_datetime, location_id, value_numeric, creator, date_created, uuid)
	SELECT DISTINCT patient_id, 5242, encounter_id, date_created, location_id, respiratoryrate, 1, date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientvitals b ON a.visit_pk=b.patientmastervisitid + 1000000
	WHERE a.encounter_datetime=b.visitdate
	AND respiratoryrate<>0;
	
INSERT INTO openmrs.obs(person_id, concept_id, encounter_id, obs_datetime, location_id, value_numeric, creator, date_created, uuid)
	SELECT DISTINCT patient_id, 5242, encounter_id, date_created, location_id, respiratoryrate, 1, date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientvitals b ON a.visit_pk=b.patientmastervisitid + 1000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	WHERE a.encounter_datetime=c.`start`
	AND respiratoryrate<>0;
	
-- #12 Heart Rate
INSERT INTO openmrs.obs(person_id, concept_id, encounter_id, obs_datetime, location_id, value_numeric, creator, date_created, uuid)
	SELECT patient_id, 5087, encounter_id, date_created, location_id, HR, 1, date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.dtl_patientvitals b ON a.visit_pk=b.visit_pk
	WHERE !ISNULL(HR);
	
INSERT INTO openmrs.obs(person_id, concept_id, encounter_id, obs_datetime, location_id, value_numeric, creator, date_created, uuid)
	SELECT DISTINCT patient_id, 5087, encounter_id, date_created, location_id, HeartRate, 1, date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientvitals b ON a.visit_pk=b.patientmastervisitid + 1000000
	WHERE a.encounter_datetime=b.visitdate
	AND HeartRate<>0;
	
INSERT INTO openmrs.obs(person_id, concept_id, encounter_id, obs_datetime, location_id, value_numeric, creator, date_created, uuid)
	SELECT DISTINCT patient_id, 5087, encounter_id, date_created, location_id, HeartRate, 1, date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientvitals b ON a.visit_pk=b.patientmastervisitid + 1000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	WHERE a.encounter_datetime=c.`start`
	AND HeartRate<>0;
	
-- #13 Muac
INSERT INTO openmrs.obs(person_id, concept_id, encounter_id, obs_datetime, location_id, value_numeric, creator, date_created, uuid)
	SELECT DISTINCT patient_id, 1343, encounter_id, date_created, location_id, Muac, 1, date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientvitals b ON a.visit_pk=b.patientmastervisitid + 1000000
	WHERE a.encounter_datetime=b.visitdate
	AND Muac<>0;
    
INSERT INTO openmrs.obs(person_id, concept_id, encounter_id, obs_datetime, location_id, value_numeric, creator, date_created, uuid)
	SELECT DISTINCT patient_id, 1343, encounter_id, date_created, location_id, Muac, 1, date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientvitals b ON a.visit_pk=b.patientmastervisitid + 1000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	WHERE a.encounter_datetime=c.`start`
	AND Muac<>0;
	
-- #14 SpO2
INSERT INTO openmrs.obs(person_id, concept_id, encounter_id, obs_datetime, location_id, value_numeric, creator, date_created, uuid)
	SELECT DISTINCT patient_id, 5092, encounter_id, date_created, location_id, SpO2, 1, date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientvitals b ON a.visit_pk=b.patientmastervisitid + 1000000
	WHERE a.encounter_datetime=b.visitdate;
    
INSERT INTO openmrs.obs(person_id, concept_id, encounter_id, obs_datetime, location_id, value_numeric, creator, date_created, uuid)
	SELECT DISTINCT patient_id, 5092, encounter_id, date_created, location_id, SpO2, 1, date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientvitals b ON a.visit_pk=b.patientmastervisitid + 1000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	WHERE a.encounter_datetime=c.`start`;

-- #15 BMI
INSERT INTO openmrs.obs(person_id, concept_id, encounter_id, obs_datetime, location_id, value_numeric, creator, date_created, uuid)
	SELECT DISTINCT patient_id, 1342, encounter_id, date_created, location_id, BMI, 1, date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientvitals b ON a.visit_pk=b.patientmastervisitid + 1000000
	WHERE a.encounter_datetime=b.visitdate
	AND BMI<>0;
    
INSERT INTO openmrs.obs(person_id, concept_id, encounter_id, obs_datetime, location_id, value_numeric, creator, date_created, uuid)
	SELECT DISTINCT patient_id, 1342, encounter_id, date_created, location_id, BMI, 1, date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientvitals b ON a.visit_pk=b.patientmastervisitid + 1000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	WHERE a.encounter_datetime=c.`start`
	AND BMI<>0;
-- End of Obs



ALTER TABLE openmrs.person DROP COLUMN ptn_pk;
ALTER TABLE openmrs.encounter DROP COLUMN visit_pk;
ALTER TABLE openmrs.visit DROP COLUMN visit_pk;

SET FOREIGN_KEY_CHECKS=1;