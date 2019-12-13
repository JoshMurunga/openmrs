SET FOREIGN_KEY_CHECKS=0;

ALTER TABLE openmrs.person ADD COLUMN ptn_pk int (10);

-- Consider also ptn_pks that are 0
INSERT INTO openmrs.person(gender, birthdate, creator, date_created, uuid, ptn_pk)
	SELECT IF(Sex=16, 'M', 'F'), DOB, 1, CreateDate, UUID(), ptn_pk FROM iqcare.mst_patient;
	
INSERT INTO openmrs.person_address(person_id, city_village, state_province, creator, date_created, county_district, uuid, address1)
	SELECT person_id, `c`.`name`, `d`.`name`, 1, date_created, `e`.`name`, UUID(), f.Address
	FROM openmrs.person a 
	INNER JOIN iqcare.mst_patient b ON a.ptn_pk=b.ptn_pk
	LEFT JOIN iqcare.mst_village c ON b.villagename=c.id 
    LEFT JOIN iqcare.mst_province d ON b.province=d.id 
    LEFT JOIN iqcare.mst_district e ON b.districtname=e.id
	LEFT JOIN iqcare.dec_bioinfo f on a.ptn_pk=f.ptn_pk;
	
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
	IF(`Marital Status`='MSM', 160578, '')))))))))), 5, 1, date_created, UUID()
	FROM openmrs.person a 
	INNER JOIN iqcare.mst_patient b ON a.ptn_pk=b.ptn_pk
	LEFT JOIN iqcare.rpt_maritalstatus c ON b.maritalstatus=c.id

	UNION SELECT person_id, IF(!ISNULL(`Phone`), `Phone`, ''), 8, 1, date_created, UUID() 
	FROM openmrs.person a 
	INNER JOIN iqcare.dec_bioinfo b ON a.ptn_pk=b.ptn_pk

	UNION SELECT person_id, IF(!ISNULL(`EmergContactName`), `EmergContactName`, ''), 11, 1, date_created, UUID() 
	FROM openmrs.person a 
	INNER JOIN iqcare.mst_patient b ON a.ptn_pk=b.ptn_pk
	LEFT JOIN iqcare.dtl_patientcontacts d ON b.ptn_pk=d.ptn_pk

	UNION SELECT person_id, IF(!ISNULL(`EmergencyContactRelation`), `EmergencyContactRelation`, ''), 12, 1, date_created, UUID() 
	FROM openmrs.person a 
	INNER JOIN iqcare.mst_patient b ON a.ptn_pk=b.ptn_pk
	LEFT JOIN iqcare.dtl_patientcontacts d ON b.ptn_pk=d.ptn_pk
	LEFT JOIN iqcare.rpt_emergencycontactrelation e ON d.EmergContactRelation=e.id

	UNION SELECT person_id, IF(!ISNULL(`EmergContactPhone`), `EmergContactPhone`, ''), 13, 1, date_created, UUID() 
	FROM openmrs.person a 
	INNER JOIN iqcare.mst_patient b ON a.ptn_pk=b.ptn_pk
	LEFT JOIN iqcare.dtl_patientcontacts d ON b.ptn_pk=d.ptn_pk

	UNION SELECT person_id, IF(!ISNULL(`EmergContactAddress`), `EmergContactAddress`, ''), 14, 1, date_created, UUID() 
	FROM openmrs.person a 
	INNER JOIN iqcare.mst_patient b ON a.ptn_pk=b.ptn_pk
	LEFT JOIN iqcare.dtl_patientcontacts d ON b.ptn_pk=d.ptn_pk;
	
DELETE FROM openmrs.person_attribute WHERE `value`='';
DELETE FROM openmrs.person_attribute WHERE `value`='NULL';
DELETE FROM openmrs.person_attribute WHERE `value`='N/A';
	
INSERT INTO openmrs.patient(patient_id, creator, date_created)
	SELECT person_id, IF(!ISNULL(creator), creator, 0), date_created FROM openmrs.person WHERE !ISNULL(ptn_pk);
	
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
	SELECT person_id, `FirstName`, IF(`MiddleName`='LName', '', `MiddleName`), `LastName`, 1, a.date_created, UUID()
	FROM openmrs.person a INNER JOIN iqcare.dec_bioinfo b ON a.ptn_pk=b.ptn_pk;
	
-- End of Patient demographic data

-- Populating Patient Program
INSERT INTO openmrs.patient_program(patient_id, program_id, date_enrolled, creator, date_created, uuid)
	SELECT person_id, 2, enrollmentdate, 1, c.createdate, UUID()
	FROM openmrs.person a
	INNER JOIN iqcare.patient b ON a.ptn_pk=b.ptn_pk
	INNER JOIN iqcare.patientenrollment c ON b.id=c.patientid;
    
INSERT INTO openmrs.patient_program(patient_id, program_id, date_enrolled, creator, date_created, uuid)
    SELECT DISTINCT patient_id, 2, `Enrollment Date`, 1, CreateDate, UUID()
	FROM openmrs.patient a
	INNER JOIN  openmrs.person b ON a.patient_id=b.person_id
	LEFT JOIN iqcare.rpt_patient c ON b.ptn_pk=c.ptn_pk
	LEFT JOIN iqcare.mst_patient d ON b.ptn_pk=d.ptn_pk
	WHERE !ISNULL(`Enrollment Date`)
	AND patient_id NOT IN
	(SELECT patient_id FROM openmrs.patient_program);
	
INSERT INTO openmrs.patient_program(patient_id, program_id, date_enrolled, creator, date_created, uuid)
	SELECT person_id, 2, startdate, 1, createdate, UUID()
	FROM openmrs.person a
	INNER JOIN iqcare.lnk_patientprogramstart b ON a.ptn_pk=b.ptn_pk
	WHERE moduleid=2 
	AND b.ptn_pk NOT IN
	(SELECT ptn_pk FROM openmrs.person a INNER JOIN openmrs.patient_program b ON a.person_id=b.patient_id);
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
	AND c.Visit_Id NOT IN (SELECT visit_pk FROM openmrs.visit f INNER JOIN iqcare.ord_visit g ON f.visit_pk=g.Visit_Id)
	
	UNION SELECT person_id, 1, `start`, IF(!ISNULL(`end`), `end`, ADDTIME(`start`, '02:00:00')), 1, d.createdate, UUID(), patientmastervisitid + 1000000
	FROM openmrs.person a
	INNER JOIN iqcare.patient b ON a.ptn_pk=b.ptn_pk
	INNER JOIN iqcare.patientvitals c ON b.id=c.patientid
	INNER JOIN iqcare.patientmastervisit d ON c.patientmastervisitid=d.id
	
	UNION SELECT person_id, 1, visitdate, ADDTIME(VisitDate, '03:00:00'), 1, a.createdate, UUID(), patientmastervisitid + 1000000
	FROM iqcare.patientvitals a 
	INNER JOIN iqcare.patient b ON a.PatientId=b.id 
	INNER JOIN openmrs.person c ON b.ptn_pk=c.ptn_pk
	WHERE patientmastervisitid 
	NOT IN 
	(SELECT id FROM iqcare.patientmastervisit)
	
	UNION SELECT DISTINCT person_id, 1, a.createdate, ADDTIME(a.createdate, '03:00:00'), 1, a.createdate, UUID(), patientmastervisitid + 2000000
	FROM iqcare.patientphdp a 
	INNER JOIN iqcare.patient b ON a.PatientId=b.id 
	INNER JOIN openmrs.person c ON b.ptn_pk=c.ptn_pk
	WHERE patientmastervisitid 
	NOT IN 
	(SELECT patientmastervisitid FROM iqcare.patientvitals)
	
	UNION SELECT DISTINCT person_id, 1, a.createdate, ADDTIME(a.createdate, '03:00:00'), 1, a.createdate, UUID(), patientmastervisitid + 3000000
	FROM iqcare.patientchronicillness a 
	INNER JOIN iqcare.patient b ON a.PatientId=b.id 
	INNER JOIN openmrs.person c ON b.ptn_pk=c.ptn_pk
	WHERE patientmastervisitid 
	NOT IN 
	(SELECT patientmastervisitid FROM iqcare.patientvitals)
	
	UNION SELECT DISTINCT person_id, 1, a.createdate, ADDTIME(a.createdate, '03:00:00'), 1, a.createdate, UUID(), patientmastervisitid + 4000000
	FROM iqcare.adherenceoutcome a 
	INNER JOIN iqcare.patient b ON a.PatientId=b.id 
	INNER JOIN openmrs.person c ON b.ptn_pk=c.ptn_pk
	WHERE adherencetype = 34 AND 
	patientmastervisitid 
	NOT IN 
	(SELECT patientmastervisitid FROM iqcare.patientvitals)
	
	UNION SELECT DISTINCT person_id, 1, a.createdate, ADDTIME(a.createdate, '03:00:00'), 1, a.createdate, UUID(), patientmastervisitid + 5000000
	FROM iqcare.adherenceassessment a 
	INNER JOIN iqcare.patient b ON a.PatientId=b.id 
	INNER JOIN openmrs.person c ON b.ptn_pk=c.ptn_pk
	WHERE patientmastervisitid 
	NOT IN 
	(SELECT patientmastervisitid FROM iqcare.patientvitals)
	
	UNION SELECT DISTINCT person_id, 1, a.createdate, ADDTIME(a.createdate, '03:00:00'), 1, a.createdate, UUID(), patientmastervisitid + 6000000
	FROM iqcare.complaintshistory a 
	INNER JOIN iqcare.patient b ON a.PatientId=b.id 
	INNER JOIN openmrs.person c ON b.ptn_pk=c.ptn_pk
	WHERE presentingcomplaint <>'' AND
	patientmastervisitid 
	NOT IN 
	(SELECT patientmastervisitid FROM iqcare.patientvitals);
	
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
	WHERE !ISNULL(temp)
	
	UNION SELECT DISTINCT patient_id, 5088, encounter_id, date_created, location_id, temperature, 1, date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientvitals b ON a.visit_pk=b.patientmastervisitid + 1000000
	WHERE a.encounter_datetime=b.visitdate
	AND temperature<>0
	
	UNION SELECT DISTINCT patient_id, 5088, encounter_id, date_created, location_id, temperature, 1, date_created, UUID()
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
	WHERE !ISNULL(BPDiastolic)
	
	UNION SELECT DISTINCT patient_id, 5086, encounter_id, date_created, location_id, BPDiastolic, 1, date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientvitals b ON a.visit_pk=b.patientmastervisitid + 1000000
	WHERE a.encounter_datetime=b.visitdate
	AND BPDiastolic<>0
	
	UNION SELECT DISTINCT patient_id, 5086, encounter_id, date_created, location_id, BPDiastolic, 1, date_created, UUID()
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
	WHERE !ISNULL(BPSystolic)
	
	UNION SELECT DISTINCT patient_id, 5085, encounter_id, date_created, location_id, BPSystolic, 1, date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientvitals b ON a.visit_pk=b.patientmastervisitid + 1000000
	WHERE a.encounter_datetime=b.visitdate
	AND BPSystolic<>0
	
	UNION SELECT DISTINCT patient_id, 5085, encounter_id, date_created, location_id, BPSystolic, 1, date_created, UUID()
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
	WHERE !ISNULL(Height)
	
	UNION SELECT DISTINCT patient_id, 5090, encounter_id, date_created, location_id, Height, 1, date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientvitals b ON a.visit_pk=b.patientmastervisitid + 1000000
	WHERE a.encounter_datetime=b.visitdate
	AND Height<>0
	
	UNION SELECT DISTINCT patient_id, 5090, encounter_id, date_created, location_id, Height, 1, date_created, UUID()
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
	WHERE !ISNULL(Weight)
	
	UNION SELECT DISTINCT patient_id, 5089, encounter_id, date_created, location_id, Weight, 1, date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientvitals b ON a.visit_pk=b.patientmastervisitid + 1000000
	WHERE a.encounter_datetime=b.visitdate
	AND Weight<>0
	
	UNION SELECT DISTINCT patient_id, 5089, encounter_id, date_created, location_id, Weight, 1, date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientvitals b ON a.visit_pk=b.patientmastervisitid + 1000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	WHERE a.encounter_datetime=c.`start`
	AND Weight<>0;
	
-- ***** HIV Form 20 Encounter ****
INSERT INTO openmrs.encounter (encounter_type, patient_id, form_id, encounter_datetime, creator, date_created, uuid)
	SELECT DISTINCT 12, patient_id, 20, IFNULL(`Enrollment Date`, `CreateDate`), 1, CreateDate, UUID()
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
	WHERE !ISNULL(`c`.`WHOStage`) AND `c`.`WHOStage`<>'0' AND `c`.`WHOStage`<>'';

-- #8 CD4 Count
INSERT INTO openmrs.obs(person_id, concept_id, encounter_id, obs_datetime, location_id, value_numeric, creator, date_created, uuid)
	SELECT patient_id, 5497, encounter_id, date_created, location_id, CD4here, 1, date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN
	(SELECT DISTINCT visit_id, IFNULL(`Most Recent CD4 - IE`, `CD4`) CD4here
	FROM iqcare.rpt_patienthivprevcareie WHERE !ISNULL(CD4))b ON a.visit_pk=b.visit_id
	
	UNION SELECT patient_id, 5497, encounter_id, date_created, location_id, ResultValue, 1, date_created, UUID()
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
	FROM iqcare.rpt_patienthivprevcareie WHERE !ISNULL(`Most Recent Viral Load - IE`))b ON a.visit_pk=b.visit_id
	
	UNION SELECT patient_id, 856, encounter_id, date_created, location_id, ResultValue, 1, date_created, UUID()
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
	WHERE !ISNULL(RR)
	
	UNION SELECT DISTINCT patient_id, 5242, encounter_id, date_created, location_id, respiratoryrate, 1, date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientvitals b ON a.visit_pk=b.patientmastervisitid + 1000000
	WHERE a.encounter_datetime=b.visitdate
	AND respiratoryrate<>0
	
	UNION SELECT DISTINCT patient_id, 5242, encounter_id, date_created, location_id, respiratoryrate, 1, date_created, UUID()
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
	WHERE !ISNULL(HR)
	
	UNION SELECT DISTINCT patient_id, 5087, encounter_id, date_created, location_id, HeartRate, 1, date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientvitals b ON a.visit_pk=b.patientmastervisitid + 1000000
	WHERE a.encounter_datetime=b.visitdate
	AND HeartRate<>0
	
	UNION SELECT DISTINCT patient_id, 5087, encounter_id, date_created, location_id, HeartRate, 1, date_created, UUID()
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
	AND Muac<>0
	
	UNION SELECT DISTINCT patient_id, 1343, encounter_id, date_created, location_id, Muac, 1, date_created, UUID()
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
	WHERE a.encounter_datetime=b.visitdate
	
	UNION SELECT DISTINCT patient_id, 5092, encounter_id, date_created, location_id, SpO2, 1, date_created, UUID()
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
	AND BMI<>0
	
	UNION SELECT DISTINCT patient_id, 1342, encounter_id, date_created, location_id, BMI, 1, date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientvitals b ON a.visit_pk=b.patientmastervisitid + 1000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	WHERE a.encounter_datetime=c.`start`
	AND BMI<>0;
	
-- #16 Patient PHDP
INSERT INTO openmrs.obs(person_id, concept_id, encounter_id, obs_datetime, location_id, value_coded, creator, date_created, UUID)
	SELECT patient_id, 
	IF(`Phdp`=72, 165358,
	IF(`Phdp`=73, 159777, 
	IF(`Phdp`=74, 112603, 
	IF(`Phdp`=75, 159423, 
	IF(`Phdp`=76, 161557, 
    IF(`Phdp`=77, 161558, NULL)))))), encounter_id, d.date_created, location_id, IF(`Phdp`=77, 664, 1065), 1, d.date_created, UUID()
	FROM iqcare.patientphdp a 
	INNER JOIN iqcare.patient b ON a.PatientId=b.id 
	INNER JOIN openmrs.person c ON b.ptn_pk=c.ptn_pk
	INNER JOIN openmrs.encounter d ON a.patientmastervisitid + 2000000 =d.visit_pk
	WHERE 
	d.encounter_datetime=a.createdate AND 
	patientmastervisitid 
	NOT IN 
	(SELECT patientmastervisitid FROM iqcare.patientvitals)
	
	UNION SELECT patient_id, 
	IF(`Phdp`=72, 165358,
	IF(`Phdp`=73, 159777, 
	IF(`Phdp`=74, 112603, 
	IF(`Phdp`=75, 159423, 
	IF(`Phdp`=76, 161557, 
    IF(`Phdp`=77, 161558, NULL)))))), encounter_id, c.date_created, location_id, IF(`Phdp`=77, 664, 1065), 1, c.date_created, UUID()
	FROM iqcare.patientphdp a
	INNER JOIN iqcare.patientvitals b ON a.patientmastervisitid=b.patientmastervisitid
	INNER JOIN openmrs.encounter c ON b.patientmastervisitid + 1000000=c.visit_pk
	WHERE b.visitdate=c.encounter_datetime
	GROUP BY a.id
	
	UNION SELECT patient_id, 
	IF(`Phdp`=72, 165358,
	IF(`Phdp`=73, 159777, 
	IF(`Phdp`=74, 112603, 
	IF(`Phdp`=75, 159423, 
	IF(`Phdp`=76, 161557, 
    IF(`Phdp`=77, 161558, NULL)))))), encounter_id, c.date_created, location_id, IF(`Phdp`=77, 664, 1065), 1, c.date_created, UUID()
	FROM iqcare.patientphdp a
	INNER JOIN iqcare.patientvitals b ON a.patientmastervisitid=b.patientmastervisitid
	INNER JOIN iqcare.patientmastervisit d ON b.patientmastervisitid=d.id 
	INNER JOIN openmrs.encounter c ON b.patientmastervisitid + 1000000=c.visit_pk
	WHERE d.`start`=c.encounter_datetime
	GROUP BY a.id;

-- #17 Patient Chronic Illness
INSERT INTO openmrs.obs(person_id, concept_id, encounter_id, obs_datetime, location_id, value_coded, creator, date_created, UUID)
	SELECT patient_id, 1284, encounter_id, d.date_created, location_id, 
    IF(`ChronicIllness`=125, 119481,
    IF(`ChronicIllness`=393, 117399,
    IF(`ChronicIllness`=379, 148432,
    IF(`ChronicIllness`=126, 159351,
    IF(`ChronicIllness`=397, 115115,
    IF(`ChronicIllness`=380, 153754,
    IF(`ChronicIllness`=395, 151342,
	IF(`ChronicIllness`=394, 117321, 
	IF(`ChronicIllness`=391, 139071, 
	IF(`ChronicIllness`=399, 117703, 
	IF(`ChronicIllness`=383, 145438, 
    IF(`ChronicIllness`=385, 120576, NULL)))))))))))), 1, d.date_created, UUID()
	FROM iqcare.patientchronicillness a 
	INNER JOIN iqcare.patient b ON a.PatientId=b.id 
	INNER JOIN openmrs.person c ON b.ptn_pk=c.ptn_pk
	INNER JOIN openmrs.encounter d ON a.patientmastervisitid + 3000000 =d.visit_pk
	WHERE 
	d.encounter_datetime=a.createdate AND 
	patientmastervisitid 
	NOT IN 
	(SELECT patientmastervisitid FROM iqcare.patientvitals)
	
	UNION SELECT patient_id, 1284, encounter_id, c.date_created, location_id, 
    IF(`ChronicIllness`=125, 119481,
    IF(`ChronicIllness`=393, 117399,
    IF(`ChronicIllness`=379, 148432,
    IF(`ChronicIllness`=126, 159351,
    IF(`ChronicIllness`=397, 115115,
    IF(`ChronicIllness`=380, 153754,
    IF(`ChronicIllness`=395, 151342,
	IF(`ChronicIllness`=394, 117321, 
	IF(`ChronicIllness`=391, 139071, 
	IF(`ChronicIllness`=399, 117703, 
	IF(`ChronicIllness`=383, 145438, 
    IF(`ChronicIllness`=385, 120576, NULL)))))))))))), 1, c.date_created, UUID()
	FROM iqcare.patientchronicillness a 
	INNER JOIN iqcare.patientvitals b ON a.patientmastervisitid=b.patientmastervisitid
	INNER JOIN openmrs.encounter c ON b.patientmastervisitid + 1000000=c.visit_pk
	WHERE b.visitdate=c.encounter_datetime
	GROUP BY a.id
	
	UNION SELECT patient_id, 1284, encounter_id, c.date_created, location_id, 
    IF(`ChronicIllness`=125, 119481,
    IF(`ChronicIllness`=393, 117399,
    IF(`ChronicIllness`=379, 148432,
    IF(`ChronicIllness`=126, 159351,
    IF(`ChronicIllness`=397, 115115,
    IF(`ChronicIllness`=380, 153754,
    IF(`ChronicIllness`=395, 151342,
	IF(`ChronicIllness`=394, 117321, 
	IF(`ChronicIllness`=391, 139071, 
	IF(`ChronicIllness`=399, 117703, 
	IF(`ChronicIllness`=383, 145438, 
    IF(`ChronicIllness`=385, 120576, NULL)))))))))))), 1, c.date_created, UUID()
	FROM iqcare.patientchronicillness a 
	INNER JOIN iqcare.patientvitals b ON a.patientmastervisitid=b.patientmastervisitid
	INNER JOIN iqcare.patientmastervisit d ON b.patientmastervisitid=d.id 
	INNER JOIN openmrs.encounter c ON b.patientmastervisitid + 1000000=c.visit_pk
	WHERE d.`start`=c.encounter_datetime
	GROUP BY a.id;
	
-- #18 Adherence Assessment
INSERT INTO openmrs.obs(person_id, concept_id, encounter_id, obs_datetime, location_id, value_coded, creator, date_created, UUID)
	SELECT patient_id, 165359, encounter_id, d.date_created, location_id, 
    IF(`ForgetMedicine`=0, 1066,
    IF(`ForgetMedicine`=1, 1065, NULL)), 1, d.date_created, UUID()
	FROM iqcare.adherenceassessment a 
	INNER JOIN iqcare.patient b ON a.PatientId=b.id 
	INNER JOIN openmrs.person c ON b.ptn_pk=c.ptn_pk
	INNER JOIN openmrs.encounter d ON a.patientmastervisitid + 5000000 =d.visit_pk
	WHERE
	d.encounter_datetime=a.createdate AND 
	patientmastervisitid 
	NOT IN 
	(SELECT patientmastervisitid FROM iqcare.patientvitals)
	
	UNION SELECT patient_id, 165359, encounter_id, c.date_created, location_id, 
    IF(`ForgetMedicine`=0, 1066,
    IF(`ForgetMedicine`=1, 1065, NULL)), 1, c.date_created, UUID()
	FROM iqcare.adherenceassessment a  
	INNER JOIN iqcare.patientvitals b ON a.patientmastervisitid=b.patientmastervisitid
	INNER JOIN openmrs.encounter c ON b.patientmastervisitid + 1000000=c.visit_pk
	WHERE b.visitdate=c.encounter_datetime
	GROUP BY a.id

	UNION SELECT patient_id, 165359, encounter_id, c.date_created, location_id, 
    IF(`ForgetMedicine`=0, 1066,
    IF(`ForgetMedicine`=1, 1065, NULL)), 1, c.date_created, UUID()
	FROM iqcare.adherenceassessment a 
	INNER JOIN iqcare.patientvitals b ON a.patientmastervisitid=b.patientmastervisitid
	INNER JOIN iqcare.patientmastervisit d ON b.patientmastervisitid=d.id 
	INNER JOIN openmrs.encounter c ON b.patientmastervisitid + 1000000=c.visit_pk
	WHERE d.`start`=c.encounter_datetime
	GROUP BY a.id
    
	UNION SELECT patient_id, 165360, encounter_id, d.date_created, location_id, 
    IF(`CarelessAboutMedicine`=0, 1066,
    IF(`CarelessAboutMedicine`=1, 1065, NULL)), 1, d.date_created, UUID()
	FROM iqcare.adherenceassessment a 
	INNER JOIN iqcare.patient b ON a.PatientId=b.id 
	INNER JOIN openmrs.person c ON b.ptn_pk=c.ptn_pk
	INNER JOIN openmrs.encounter d ON a.patientmastervisitid + 5000000 =d.visit_pk
	WHERE
	d.encounter_datetime=a.createdate AND 
	patientmastervisitid 
	NOT IN 
	(SELECT patientmastervisitid FROM iqcare.patientvitals)
	
	UNION SELECT patient_id, 165360, encounter_id, c.date_created, location_id, 
    IF(`CarelessAboutMedicine`=0, 1066,
    IF(`CarelessAboutMedicine`=1, 1065, NULL)), 1, c.date_created, UUID()
	FROM iqcare.adherenceassessment a  
	INNER JOIN iqcare.patientvitals b ON a.patientmastervisitid=b.patientmastervisitid
	INNER JOIN openmrs.encounter c ON b.patientmastervisitid + 1000000=c.visit_pk
	WHERE b.visitdate=c.encounter_datetime
	GROUP BY a.id

	UNION SELECT patient_id, 165360, encounter_id, c.date_created, location_id, 
    IF(`CarelessAboutMedicine`=0, 1066,
    IF(`CarelessAboutMedicine`=1, 1065, NULL)), 1, c.date_created, UUID()
	FROM iqcare.adherenceassessment a 
	INNER JOIN iqcare.patientvitals b ON a.patientmastervisitid=b.patientmastervisitid
	INNER JOIN iqcare.patientmastervisit d ON b.patientmastervisitid=d.id 
	INNER JOIN openmrs.encounter c ON b.patientmastervisitid + 1000000=c.visit_pk
	WHERE d.`start`=c.encounter_datetime
	GROUP BY a.id
    
	UNION SELECT patient_id, 165361, encounter_id, d.date_created, location_id, 
    IF(`FeelWorse`=0, 1066,
    IF(`FeelWorse`=1, 1065, NULL)), 1, d.date_created, UUID()
	FROM iqcare.adherenceassessment a 
	INNER JOIN iqcare.patient b ON a.PatientId=b.id 
	INNER JOIN openmrs.person c ON b.ptn_pk=c.ptn_pk
	INNER JOIN openmrs.encounter d ON a.patientmastervisitid + 5000000 =d.visit_pk
	WHERE
	d.encounter_datetime=a.createdate AND 
	patientmastervisitid 
	NOT IN 
	(SELECT patientmastervisitid FROM iqcare.patientvitals)
	
	UNION SELECT patient_id, 165361, encounter_id, c.date_created, location_id, 
    IF(`FeelWorse`=0, 1066,
    IF(`FeelWorse`=1, 1065, NULL)), 1, c.date_created, UUID()
	FROM iqcare.adherenceassessment a  
	INNER JOIN iqcare.patientvitals b ON a.patientmastervisitid=b.patientmastervisitid
	INNER JOIN openmrs.encounter c ON b.patientmastervisitid + 1000000=c.visit_pk
	WHERE b.visitdate=c.encounter_datetime
	GROUP BY a.id

	UNION SELECT patient_id, 165361, encounter_id, c.date_created, location_id, 
    IF(`FeelWorse`=0, 1066,
    IF(`FeelWorse`=1, 1065, NULL)), 1, c.date_created, UUID()
	FROM iqcare.adherenceassessment a 
	INNER JOIN iqcare.patientvitals b ON a.patientmastervisitid=b.patientmastervisitid
	INNER JOIN iqcare.patientmastervisit d ON b.patientmastervisitid=d.id 
	INNER JOIN openmrs.encounter c ON b.patientmastervisitid + 1000000=c.visit_pk
	WHERE d.`start`=c.encounter_datetime
	GROUP BY a.id
    
	UNION SELECT patient_id, 165362, encounter_id, d.date_created, location_id, 
    IF(`FeelBetter`=0, 1066,
    IF(`FeelBetter`=1, 1065, NULL)), 1, d.date_created, UUID()
	FROM iqcare.adherenceassessment a 
	INNER JOIN iqcare.patient b ON a.PatientId=b.id 
	INNER JOIN openmrs.person c ON b.ptn_pk=c.ptn_pk
	INNER JOIN openmrs.encounter d ON a.patientmastervisitid + 5000000 =d.visit_pk
	WHERE
	d.encounter_datetime=a.createdate AND 
	patientmastervisitid 
	NOT IN 
	(SELECT patientmastervisitid FROM iqcare.patientvitals)
	
	UNION SELECT patient_id, 165362, encounter_id, c.date_created, location_id, 
    IF(`FeelBetter`=0, 1066,
    IF(`FeelBetter`=1, 1065, NULL)), 1, c.date_created, UUID()
	FROM iqcare.adherenceassessment a  
	INNER JOIN iqcare.patientvitals b ON a.patientmastervisitid=b.patientmastervisitid
	INNER JOIN openmrs.encounter c ON b.patientmastervisitid + 1000000=c.visit_pk
	WHERE b.visitdate=c.encounter_datetime
	GROUP BY a.id

	UNION SELECT patient_id, 165362, encounter_id, c.date_created, location_id, 
    IF(`FeelBetter`=0, 1066,
    IF(`FeelBetter`=1, 1065, NULL)), 1, c.date_created, UUID()
	FROM iqcare.adherenceassessment a 
	INNER JOIN iqcare.patientvitals b ON a.patientmastervisitid=b.patientmastervisitid
	INNER JOIN iqcare.patientmastervisit d ON b.patientmastervisitid=d.id 
	INNER JOIN openmrs.encounter c ON b.patientmastervisitid + 1000000=c.visit_pk
	WHERE d.`start`=c.encounter_datetime
	GROUP BY a.id;

-- #19 Adherence Outcome
INSERT INTO openmrs.obs(person_id, concept_id, encounter_id, obs_datetime, location_id, value_coded, creator, date_created, UUID)
	SELECT patient_id, 1658, encounter_id, d.date_created, location_id, 
    IF(`Score`=68, 159405,
    IF(`Score`=69, 163794,
    IF(`Score`=70, 159406,
    IF(`Score`=71, 159407, NULL)))), 1, d.date_created, UUID()
	FROM iqcare.adherenceoutcome a 
	INNER JOIN iqcare.patient b ON a.PatientId=b.id 
	INNER JOIN openmrs.person c ON b.ptn_pk=c.ptn_pk
	INNER JOIN openmrs.encounter d ON a.patientmastervisitid + 4000000 =d.visit_pk
	WHERE 
    adherencetype = 34 AND
	d.encounter_datetime=a.createdate AND 
	patientmastervisitid 
	NOT IN 
	(SELECT patientmastervisitid FROM iqcare.patientvitals)
	
	UNION SELECT patient_id, 1658, encounter_id, c.date_created, location_id, 
    IF(`Score`=68, 159405,
    IF(`Score`=69, 163794,
    IF(`Score`=70, 159406,
    IF(`Score`=71, 159407, NULL)))), 1, c.date_created, UUID()
	FROM iqcare.adherenceoutcome a 
	INNER JOIN iqcare.patientvitals b ON a.patientmastervisitid=b.patientmastervisitid
	INNER JOIN openmrs.encounter c ON b.patientmastervisitid + 1000000=c.visit_pk
	WHERE b.visitdate=c.encounter_datetime AND
    adherencetype = 34
	GROUP BY a.id
	
	UNION SELECT patient_id, 1658, encounter_id, c.date_created, location_id, 
    IF(`Score`=68, 159405,
    IF(`Score`=69, 163794,
    IF(`Score`=70, 159406,
    IF(`Score`=71, 159407, NULL)))), 1, c.date_created, UUID()
	FROM iqcare.adherenceoutcome a 
	INNER JOIN iqcare.patientvitals b ON a.patientmastervisitid=b.patientmastervisitid
	INNER JOIN iqcare.patientmastervisit d ON b.patientmastervisitid=d.id 
	INNER JOIN openmrs.encounter c ON b.patientmastervisitid + 1000000=c.visit_pk
	WHERE d.`start`=c.encounter_datetime AND
    adherencetype = 34
	GROUP BY a.id;
	
-- #20 Complaint History
INSERT INTO openmrs.obs(person_id, concept_id, encounter_id, obs_datetime, location_id, value_coded, creator, date_created, UUID)
	SELECT patient_id, 5219, encounter_id, d.date_created, location_id, 5622, 1, d.date_created, UUID()
	FROM iqcare.complaintshistory a 
	INNER JOIN iqcare.patient b ON a.PatientId=b.id 
	INNER JOIN openmrs.person c ON b.ptn_pk=c.ptn_pk
	INNER JOIN openmrs.encounter d ON a.patientmastervisitid + 6000000 =d.visit_pk
	WHERE 
    presentingcomplaint <>'' AND
	d.encounter_datetime=a.createdate AND 
	patientmastervisitid 
	NOT IN 
	(SELECT patientmastervisitid FROM iqcare.patientvitals)
	
	UNION SELECT patient_id, 5219, encounter_id, c.date_created, location_id, 5266, 1, c.date_created, UUID()
	FROM iqcare.complaintshistory a 
	INNER JOIN iqcare.patientvitals b ON a.patientmastervisitid=b.patientmastervisitid
	INNER JOIN openmrs.encounter c ON b.patientmastervisitid + 1000000=c.visit_pk
	WHERE b.visitdate=c.encounter_datetime AND
    presentingcomplaint <>''
	GROUP BY a.id
	
	UNION SELECT patient_id, 5219, encounter_id, c.date_created, location_id, 5266, 1, c.date_created, UUID()
	FROM iqcare.complaintshistory a 
	INNER JOIN iqcare.patientvitals b ON a.patientmastervisitid=b.patientmastervisitid
	INNER JOIN iqcare.patientmastervisit d ON b.patientmastervisitid=d.id 
	INNER JOIN openmrs.encounter c ON b.patientmastervisitid + 1000000=c.visit_pk
	WHERE d.`start`=c.encounter_datetime AND
    presentingcomplaint <>''
	GROUP BY a.id;
	
INSERT INTO openmrs.obs(person_id, concept_id, encounter_id, obs_datetime, location_id, value_text, creator, date_created, UUID)
	SELECT patient_id, 160430, encounter_id, d.date_created, location_id, presentingcomplaint, 1, d.date_created, UUID()
	FROM iqcare.complaintshistory a 
	INNER JOIN iqcare.patient b ON a.PatientId=b.id 
	INNER JOIN openmrs.person c ON b.ptn_pk=c.ptn_pk
	INNER JOIN openmrs.encounter d ON a.patientmastervisitid + 6000000 =d.visit_pk
	WHERE 
    presentingcomplaint <>'' AND
	d.encounter_datetime=a.createdate AND 
	patientmastervisitid 
	NOT IN 
	(SELECT patientmastervisitid FROM iqcare.patientvitals)
	
	UNION SELECT patient_id, 160430, encounter_id, c.date_created, location_id, presentingcomplaint, 1, c.date_created, UUID()
	FROM iqcare.complaintshistory a 
	INNER JOIN iqcare.patientvitals b ON a.patientmastervisitid=b.patientmastervisitid
	INNER JOIN openmrs.encounter c ON b.patientmastervisitid + 1000000=c.visit_pk
	WHERE b.visitdate=c.encounter_datetime AND
    presentingcomplaint <>''
	GROUP BY a.id
	
	UNION SELECT patient_id, 160430, encounter_id, c.date_created, location_id, presentingcomplaint, 1, c.date_created, UUID()
	FROM iqcare.complaintshistory a 
	INNER JOIN iqcare.patientvitals b ON a.patientmastervisitid=b.patientmastervisitid
	INNER JOIN iqcare.patientmastervisit d ON b.patientmastervisitid=d.id 
	INNER JOIN openmrs.encounter c ON b.patientmastervisitid + 1000000=c.visit_pk
	WHERE d.`start`=c.encounter_datetime AND
    presentingcomplaint <>''
	GROUP BY a.id;

-- #21 Lab
--- lab encounter
INSERT INTO openmrs.encounter (encounter_type, patient_id, encounter_datetime, creator, date_created, `uuid`, visit_pk)
	SELECT 30, person_id, orderdate, 1, b.createdate, UUID(), visitid + 7000000
	FROM openmrs.person a
	INNER JOIN iqcare.ord_laborder b ON a.ptn_pk=b.ptn_pk
	INNER JOIN iqcare.dtl_labordertest c ON b.id=c.laborderid
	INNER JOIN iqcare.dtl_labordertestresult d ON c.id=d.labordertestid
	WHERE resultstatus = 'Received'
	AND !ISNULL(resultdate)
	AND !ISNULL(resultvalue)
	AND ISNULL(resulttext)
	
	UNION SELECT 30, person_id, orderdate, 1, b.createdate, UUID(), visitid + 7000000
	FROM openmrs.person a
	INNER JOIN iqcare.ord_laborder b ON a.ptn_pk=b.ptn_pk
	INNER JOIN iqcare.dtl_labordertest c ON b.id=c.laborderid
	INNER JOIN iqcare.dtl_labordertestresult d ON c.id=d.labordertestid
	WHERE resultstatus = 'Received'
	AND !ISNULL(resultdate)
	AND !ISNULL(resulttext)
	AND ISNULL(resultvalue);

INSERT INTO openmrs.encounter (encounter_type, patient_id, encounter_datetime, creator, date_created, `uuid`, visit_pk)
	SELECT 30, person_id, resultdate, 1, b.createdate, UUID(), visitid + 8000000
	FROM openmrs.person a
	INNER JOIN iqcare.ord_laborder b ON a.ptn_pk=b.ptn_pk
	INNER JOIN iqcare.dtl_labordertest c ON b.id=c.laborderid
	INNER JOIN iqcare.dtl_labordertestresult d ON c.id=d.labordertestid
	WHERE resultstatus = 'Received' 
	AND !ISNULL(resultdate)
	AND !ISNULL(resultvalue)
	AND ISNULL(resulttext)
	
	UNION SELECT 30, person_id, resultdate, 1, b.createdate, UUID(), visitid + 8000000
	FROM openmrs.person a
	INNER JOIN iqcare.ord_laborder b ON a.ptn_pk=b.ptn_pk
	INNER JOIN iqcare.dtl_labordertest c ON b.id=c.laborderid
	INNER JOIN iqcare.dtl_labordertestresult d ON c.id=d.labordertestid
	WHERE resultstatus = 'Received' 
	AND !ISNULL(resultdate)
	AND !ISNULL(resulttext)
	AND ISNULL(resultvalue);
	
--- lab orders
ALTER TABLE openmrs.orders ADD COLUMN labresult_pk int (10);

SET @ord:= IF(ISNULL((SELECT MAX(order_id) FROM openmrs.orders)), 0, (SELECT MAX(order_id) FROM openmrs.orders));

INSERT INTO openmrs.orders (order_type_id, concept_id, orderer, encounter_id, date_activated, date_stopped, creator, date_created, patient_id, `uuid`, order_number, order_action, care_setting, labresult_pk)
	SELECT 3, 
	IF(parameterid=1, 5497, IF(parameterid=2, 730, IF(parameterid=3, 856, IF(parameterid=5, 1015, IF(parameterid=6, 1015,
	IF(parameterid=7, 678, IF(parameterid=9, 729, IF(parameterid=10, 653, IF(parameterid=11, 654, IF(parameterid=12, 790,
	IF(parameterid=13, 1299, IF(parameterid=15, 32, IF(parameterid=17, 307, IF(parameterid=28, 679, IF(parameterid=116, 163722,
	IF(parameterid=53, 163722, IF(parameterid=101, 163722, IF(parameterid=55, 161447, IF(parameterid=105, 161447, IF(parameterid=62, 1007,
	IF(parameterid=69, 1008, IF(parameterid=75, 1619, IF(parameterid=76, 1006, IF(parameterid=78, 1009, IF(parameterid=83, 1336,
	IF(parameterid=85, 1338, IF(parameterid=90, 161439, IF(parameterid=91, 159733, IF(parameterid=92, 161442, IF(parameterid=93, 1875,
	IF(parameterid=94, 161441, IF(parameterid=95, 161440, IF(parameterid=96, 162096, IF(parameterid=114, 1030, IF(parameterid=20, 161454,
	IF(parameterid=68, 159430, IF(parameterid=108, 1325, IF(parameterid=4, 165363, IF(parameterid=14, 45, IF(parameterid=16, 163613,
	IF(parameterid=23, 163613, IF(parameterid=54, 159647, IF(parameterid=74, 165364, IF(parameterid=82, 1022, IF(parameterid=84, 1021,
	IF(parameterid=86, 1023, IF(parameterid=87, 1339, IF(parameterid=88, 1024, IF(parameterid=89, 1340, IF(parameterid=22, 161156,
	IF(parameterid=65, 165365, IF(parameterid=66, 165366, IF(parameterid=67, 165367, IF(parameterid=71, 165368, IF(parameterid=72, 165369,
	IF(parameterid=79, 164977, IF(parameterid=117, 163126, NULL))))))))))))))))))))))))))))))))))))))))))))))))))))))))),
	2, encounter_id, orderdate, resultdate, 1, d.createdate, patient_id, UUID(), CONCAT("ORD-", (SELECT IF(ISNULL(@ord), 0, @ord:=@ord+1))), "NEW", 1, d.id
	FROM openmrs.encounter a
	INNER JOIN iqcare.ord_laborder b ON a.visit_pk=b.visitid + 7000000
	INNER JOIN iqcare.dtl_labordertest c ON b.id=c.laborderid
	INNER JOIN iqcare.dtl_labordertestresult d ON c.id=d.labordertestid
	WHERE encounter_datetime=orderdate
	AND resultstatus = 'Received'
	AND !ISNULL(resultdate)
	AND !ISNULL(resultvalue)
	AND ISNULL(resulttext)
	GROUP BY d.id

	UNION SELECT 3, 
	IF(parameterid=1, 5497, IF(parameterid=2, 730, IF(parameterid=3, 856, IF(parameterid=5, 1015, IF(parameterid=6, 1015,
	IF(parameterid=7, 678, IF(parameterid=9, 729, IF(parameterid=10, 653, IF(parameterid=11, 654, IF(parameterid=12, 790,
	IF(parameterid=13, 1299, IF(parameterid=15, 32, IF(parameterid=17, 307, IF(parameterid=28, 679, IF(parameterid=116, 163722,
	IF(parameterid=53, 163722, IF(parameterid=101, 163722, IF(parameterid=55, 161447, IF(parameterid=105, 161447, IF(parameterid=62, 1007,
	IF(parameterid=69, 1008, IF(parameterid=75, 1619, IF(parameterid=76, 1006, IF(parameterid=78, 1009, IF(parameterid=83, 1336,
	IF(parameterid=85, 1338, IF(parameterid=90, 161439, IF(parameterid=91, 159733, IF(parameterid=92, 161442, IF(parameterid=93, 1875,
	IF(parameterid=94, 161441, IF(parameterid=95, 161440, IF(parameterid=96, 162096, IF(parameterid=114, 1030, IF(parameterid=20, 161454,
	IF(parameterid=68, 159430, IF(parameterid=108, 1325, IF(parameterid=4, 165363, IF(parameterid=14, 45, IF(parameterid=16, 163613,
	IF(parameterid=23, 163613, IF(parameterid=54, 159647, IF(parameterid=74, 165364, IF(parameterid=82, 1022, IF(parameterid=84, 1021,
	IF(parameterid=86, 1023, IF(parameterid=87, 1339, IF(parameterid=88, 1024, IF(parameterid=89, 1340, IF(parameterid=22, 161156,
	IF(parameterid=65, 165365, IF(parameterid=66, 165366, IF(parameterid=67, 165367, IF(parameterid=71, 165368, IF(parameterid=72, 165369,
	IF(parameterid=79, 164977, IF(parameterid=117, 163126, NULL))))))))))))))))))))))))))))))))))))))))))))))))))))))))),
	2, encounter_id, orderdate, resultdate, 1, d.createdate, patient_id, UUID(), CONCAT("ORD-", (SELECT IF(ISNULL(@ord), 0, @ord:=@ord+1))), "NEW", 1, d.id
	FROM openmrs.encounter a
	INNER JOIN iqcare.ord_laborder b ON a.visit_pk=b.visitid + 7000000
	INNER JOIN iqcare.dtl_labordertest c ON b.id=c.laborderid
	INNER JOIN iqcare.dtl_labordertestresult d ON c.id=d.labordertestid
	WHERE encounter_datetime=orderdate
	AND resultstatus = 'Received'
	AND !ISNULL(resultdate)
	AND !ISNULL(resulttext)
	AND ISNULL(resultvalue)
	GROUP BY d.id;
	
INSERT INTO openmrs.orders (order_type_id, concept_id, orderer, encounter_id, date_activated, auto_expire_date, creator, date_created, patient_id, `uuid`, order_number, order_action, care_setting, labresult_pk)
	SELECT 3, 
	IF(parameterid=1, 5497, IF(parameterid=2, 730, IF(parameterid=3, 856, IF(parameterid=5, 1015, IF(parameterid=6, 1015,
	IF(parameterid=7, 678, IF(parameterid=9, 729, IF(parameterid=10, 653, IF(parameterid=11, 654, IF(parameterid=12, 790,
	IF(parameterid=13, 1299, IF(parameterid=15, 32, IF(parameterid=17, 307, IF(parameterid=28, 679, IF(parameterid=116, 163722,
	IF(parameterid=53, 163722, IF(parameterid=101, 163722, IF(parameterid=55, 161447, IF(parameterid=105, 161447, IF(parameterid=62, 1007,
	IF(parameterid=69, 1008, IF(parameterid=75, 1619, IF(parameterid=76, 1006, IF(parameterid=78, 1009, IF(parameterid=83, 1336,
	IF(parameterid=85, 1338, IF(parameterid=90, 161439, IF(parameterid=91, 159733, IF(parameterid=92, 161442, IF(parameterid=93, 1875,
	IF(parameterid=94, 161441, IF(parameterid=95, 161440, IF(parameterid=96, 162096, IF(parameterid=114, 1030, IF(parameterid=20, 161454,
	IF(parameterid=68, 159430, IF(parameterid=108, 1325, IF(parameterid=4, 165363, IF(parameterid=14, 45, IF(parameterid=16, 163613,
	IF(parameterid=23, 163613, IF(parameterid=54, 159647, IF(parameterid=74, 165364, IF(parameterid=82, 1022, IF(parameterid=84, 1021,
	IF(parameterid=86, 1023, IF(parameterid=87, 1339, IF(parameterid=88, 1024, IF(parameterid=89, 1340, IF(parameterid=22, 161156,
	IF(parameterid=65, 165365, IF(parameterid=66, 165366, IF(parameterid=67, 165367, IF(parameterid=71, 165368, IF(parameterid=72, 165369,
	IF(parameterid=79, 164977, IF(parameterid=117, 163126, NULL))))))))))))))))))))))))))))))))))))))))))))))))))))))))),
	2, encounter_id, resultdate, resultdate, 1, d.createdate, patient_id, UUID(), CONCAT("ORD-", (SELECT IF(ISNULL(@ord), 0, @ord:=@ord+1))), "DISCONTINUE", 1, d.id
	FROM openmrs.encounter a
	INNER JOIN iqcare.ord_laborder b ON a.visit_pk=b.visitid + 8000000
	INNER JOIN iqcare.dtl_labordertest c ON b.id=c.laborderid
	INNER JOIN iqcare.dtl_labordertestresult d ON c.id=d.labordertestid
	WHERE encounter_datetime=resultdate
	AND resultstatus = 'Received'
	AND !ISNULL(resultdate)
	AND !ISNULL(resultvalue)
	AND ISNULL(resulttext)
	GROUP BY d.id
	
	UNION SELECT 3, 
	IF(parameterid=1, 5497, IF(parameterid=2, 730, IF(parameterid=3, 856, IF(parameterid=5, 1015, IF(parameterid=6, 1015,
	IF(parameterid=7, 678, IF(parameterid=9, 729, IF(parameterid=10, 653, IF(parameterid=11, 654, IF(parameterid=12, 790,
	IF(parameterid=13, 1299, IF(parameterid=15, 32, IF(parameterid=17, 307, IF(parameterid=28, 679, IF(parameterid=116, 163722,
	IF(parameterid=53, 163722, IF(parameterid=101, 163722, IF(parameterid=55, 161447, IF(parameterid=105, 161447, IF(parameterid=62, 1007,
	IF(parameterid=69, 1008, IF(parameterid=75, 1619, IF(parameterid=76, 1006, IF(parameterid=78, 1009, IF(parameterid=83, 1336,
	IF(parameterid=85, 1338, IF(parameterid=90, 161439, IF(parameterid=91, 159733, IF(parameterid=92, 161442, IF(parameterid=93, 1875,
	IF(parameterid=94, 161441, IF(parameterid=95, 161440, IF(parameterid=96, 162096, IF(parameterid=114, 1030, IF(parameterid=20, 161454,
	IF(parameterid=68, 159430, IF(parameterid=108, 1325, IF(parameterid=4, 165363, IF(parameterid=14, 45, IF(parameterid=16, 163613,
	IF(parameterid=23, 163613, IF(parameterid=54, 159647, IF(parameterid=74, 165364, IF(parameterid=82, 1022, IF(parameterid=84, 1021,
	IF(parameterid=86, 1023, IF(parameterid=87, 1339, IF(parameterid=88, 1024, IF(parameterid=89, 1340, IF(parameterid=22, 161156,
	IF(parameterid=65, 165365, IF(parameterid=66, 165366, IF(parameterid=67, 165367, IF(parameterid=71, 165368, IF(parameterid=72, 165369,
	IF(parameterid=79, 164977, IF(parameterid=117, 163126, NULL))))))))))))))))))))))))))))))))))))))))))))))))))))))))),
	2, encounter_id, resultdate, resultdate, 1, d.createdate, patient_id, UUID(), CONCAT("ORD-", (SELECT IF(ISNULL(@ord), 0, @ord:=@ord+1))), "DISCONTINUE", 1, d.id
	FROM openmrs.encounter a
	INNER JOIN iqcare.ord_laborder b ON a.visit_pk=b.visitid + 8000000
	INNER JOIN iqcare.dtl_labordertest c ON b.id=c.laborderid
	INNER JOIN iqcare.dtl_labordertestresult d ON c.id=d.labordertestid
	WHERE encounter_datetime=resultdate
	AND resultstatus = 'Received'
	AND !ISNULL(resultdate)
	AND !ISNULL(resulttext)
	AND ISNULL(resultvalue)
	GROUP BY d.id;
	
---lab results
INSERT INTO openmrs.obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_coded, creator, date_created, `uuid`)
	SELECT a.patient_id, concept_id, e.encounter_id, order_id, date_stopped,
	IF(resultvalue=1, 703, IF(resultvalue=0, 664, IF(resultvalue=3, 1138, NULL))), 1, d.createdate, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.ord_laborder b ON a.visit_pk=b.visitid + 7000000
	INNER JOIN iqcare.dtl_labordertest c ON b.id=c.laborderid
	INNER JOIN iqcare.dtl_labordertestresult d ON c.id=d.labordertestid
	INNER JOIN openmrs.orders e ON a.encounter_id=e.encounter_id 
	WHERE parameterid IN (4,14,15,17,116,53,101,74,75,92,93,94,95,96,114,65,66,67,68,71,72,79,108,117)
	AND !ISNULL(resultvalue)
	AND ISNULL(resulttext)
	AND encounter_datetime=orderdate
	AND labresult_pk=d.id
	GROUP BY d.id
	ORDER BY FIELD(parameterid, 4,14,15,17,116,53,101,74,75,92,93,94,95,96,114,65,66,67,68,71,72,79,108,117);
	
INSERT INTO openmrs.obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_coded, creator, date_created, `uuid`)
	SELECT a.patient_id, concept_id, e.encounter_id, order_id, date_stopped,
	IF(resulttext='POSITIVE', 703,
	IF(resulttext='pos', 703,
	IF(resulttext='neg', 664,
	IF(resulttext='No MPS Seen', 664,
	IF(resulttext='Neagative', 664,
	IF(resulttext='Ne', 664,
	IF(resulttext='N', 664,
	IF(resulttext='Non-Reactive', 1229,
	IF(resulttext='A+', 163115,
	IF(resulttext='O+', 163118,
	IF(resulttext='NEGATIVE', 664, NULL))))))))))),
	1, d.createdate, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.ord_laborder b ON a.visit_pk=b.visitid + 7000000
	INNER JOIN iqcare.dtl_labordertest c ON b.id=c.laborderid
	INNER JOIN iqcare.dtl_labordertestresult d ON c.id=d.labordertestid
	INNER JOIN openmrs.orders e ON a.encounter_id=e.encounter_id 
	WHERE parameterid IN (14,15,116,101,75,114,65,66,67,68,71,72,79,108,117)
	AND ISNULL(resultvalue)
	AND !ISNULL(resulttext)
	AND encounter_datetime=orderdate
	AND labresult_pk=d.id
	AND resulttext<>'select'
	GROUP BY d.id
	ORDER BY FIELD(parameterid, 14,15,116,101,75,114,65,66,67,68,71,72,79,108,117);

INSERT INTO openmrs.obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_numeric, creator, date_created, `uuid`)
	SELECT a.patient_id, concept_id, e.encounter_id, order_id, date_stopped, resultvalue, 1, d.createdate, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.ord_laborder b ON a.visit_pk=b.visitid + 7000000
	INNER JOIN iqcare.dtl_labordertest c ON b.id=c.laborderid
	INNER JOIN iqcare.dtl_labordertestresult d ON c.id=d.labordertestid
	INNER JOIN openmrs.orders e ON a.encounter_id=e.encounter_id 
	WHERE parameterid IN (1,2,3,5,6,7,9,10,11,12,13,28,54,62,69,76,78,82,83,84,85,86,87,88,89,90,91)
	AND !ISNULL(resultvalue)
	AND ISNULL(resulttext)
	AND encounter_datetime=orderdate
	AND labresult_pk=d.id
	GROUP BY d.id
	ORDER BY FIELD(parameterid, 1,2,3,5,6,7,9,10,11,12,13,28,54,62,69,76,78,82,83,84,85,86,87,88,89,90,91);
	
INSERT IGNORE INTO openmrs.obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_numeric, creator, date_created, `uuid`)
	SELECT a.patient_id, concept_id, e.encounter_id, order_id, date_stopped, CAST(resulttext AS DECIMAL(18,2)), 1, d.createdate, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.ord_laborder b ON a.visit_pk=b.visitid + 7000000
	INNER JOIN iqcare.dtl_labordertest c ON b.id=c.laborderid
	INNER JOIN iqcare.dtl_labordertestresult d ON c.id=d.labordertestid
	INNER JOIN openmrs.orders e ON a.encounter_id=e.encounter_id 
	WHERE parameterid IN (62,69,76,78)
	AND ISNULL(resultvalue)
	AND !ISNULL(resulttext)
	AND encounter_datetime=orderdate
	AND labresult_pk=d.id
	GROUP BY d.id
	ORDER BY FIELD(parameterid, 62,69,76,78);

INSERT INTO openmrs.obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_text, creator, date_created, `uuid`)
	SELECT a.patient_id, concept_id, e.encounter_id, order_id, date_stopped, resulttext, 1, d.createdate, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.ord_laborder b ON a.visit_pk=b.visitid + 7000000
	INNER JOIN iqcare.dtl_labordertest c ON b.id=c.laborderid
	INNER JOIN iqcare.dtl_labordertestresult d ON c.id=d.labordertestid
	INNER JOIN openmrs.orders e ON a.encounter_id=e.encounter_id 
	WHERE parameterid IN (55,105,20,22,16,23)
	AND ISNULL(resultvalue)
	AND !ISNULL(resulttext)
	AND encounter_datetime=orderdate
	AND labresult_pk=d.id
	GROUP BY d.id
	ORDER BY FIELD(parameterid, 55,105,20,22,16,23);
	
INSERT INTO openmrs.obs (person_id, concept_id, encounter_id, order_id, obs_datetime, value_text, creator, date_created, `uuid`)
	SELECT a.patient_id, concept_id, e.encounter_id, order_id, date_stopped, IF(resultvalue=0, "Negative", IF(resultvalue=1, "Positive", NULL)), 1, d.createdate, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.ord_laborder b ON a.visit_pk=b.visitid + 7000000
	INNER JOIN iqcare.dtl_labordertest c ON b.id=c.laborderid
	INNER JOIN iqcare.dtl_labordertestresult d ON c.id=d.labordertestid
	INNER JOIN openmrs.orders e ON a.encounter_id=e.encounter_id 
	WHERE parameterid IN (16,23)
	AND ISNULL(resulttext)
	AND !ISNULL(resultvalue)
	AND encounter_datetime=orderdate
	AND labresult_pk=d.id
	GROUP BY d.id
	ORDER BY FIELD(parameterid, 16,23);

-- End of Obs



ALTER TABLE openmrs.person DROP COLUMN ptn_pk;
ALTER TABLE openmrs.encounter DROP COLUMN visit_pk;
ALTER TABLE openmrs.visit DROP COLUMN visit_pk;
ALTER TABLE openmrs.orders DROP COLUMN labresult_pk;

SET FOREIGN_KEY_CHECKS=1;