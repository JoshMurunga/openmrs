SET FOREIGN_KEY_CHECKS=0;

ALTER TABLE openmrs.person ADD COLUMN ptn_pk int (10);

-- Consider also ptn_pks that are 0
INSERT INTO openmrs.person(gender, birthdate, creator, date_created, `uuid`, ptn_pk)
	SELECT IF(Sex=16, 'M', 'F'), DOB, 1, CreateDate, UUID(), ptn_pk FROM iqcare.mst_patient;
	
INSERT INTO openmrs.person_address(person_id, city_village, state_province, creator, date_created, county_district, `uuid`, address1)
	SELECT person_id, `c`.`name`, `d`.`name`, 1, date_created, `e`.`name`, UUID(), f.Address
	FROM openmrs.person a 
	INNER JOIN iqcare.mst_patient b ON a.ptn_pk=b.ptn_pk
	LEFT JOIN iqcare.mst_village c ON b.villagename=c.id 
    LEFT JOIN iqcare.mst_province d ON b.province=d.id 
    LEFT JOIN iqcare.mst_district e ON b.districtname=e.id
	LEFT JOIN iqcare.dec_bioinfo f on a.ptn_pk=f.ptn_pk;
	
INSERT INTO openmrs.person_attribute(person_id, `value`, person_attribute_type_id, creator, date_created, `uuid`)
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
	
INSERT INTO openmrs.patient_identifier(patient_id, identifier, identifier_type, location_id, creator, date_created, `uuid`)
	SELECT patient_id, IF(!ISNULL(HTSID), HTSID, ''), 4, location_id, 1, a.date_created, UUID()
	FROM openmrs.patient a 
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
    FROM openmrs.patient a
	INNER JOIN openmrs.person b ON a.patient_id=b.person_id
	INNER JOIN iqcare.mst_patient c ON b.ptn_pk=c.ptn_pk
	LEFT JOIN iqcare.mst_facility d ON c.LocationID=d.FacilityID
	LEFT JOIN openmrs.location e ON d.FacilityName=e.name;
	
DELETE FROM openmrs.patient_identifier WHERE `identifier`='';
DELETE FROM openmrs.patient_identifier WHERE `identifier`='NULL';
DELETE FROM openmrs.patient_identifier WHERE `identifier`='N/A';	

INSERT INTO openmrs.person_name(person_id, given_name, middle_name, family_name, creator, date_created, `uuid`)
	SELECT person_id, `FirstName`, IF(`MiddleName`='LName', '', `MiddleName`), `LastName`, 1, a.date_created, UUID()
	FROM openmrs.person a INNER JOIN iqcare.dec_bioinfo b ON a.ptn_pk=b.ptn_pk;
	
-- End of Patient demographic data

-- Populating Patient Program
INSERT INTO openmrs.patient_program(patient_id, program_id, date_enrolled, creator, date_created, `uuid`)
	SELECT person_id, 2, enrollmentdate, 1, c.createdate, UUID()
	FROM openmrs.person a
	INNER JOIN iqcare.patient b ON a.ptn_pk=b.ptn_pk
	INNER JOIN iqcare.patientenrollment c ON b.id=c.patientid;
    
INSERT INTO openmrs.patient_program(patient_id, program_id, date_enrolled, creator, date_created, `uuid`)
    SELECT DISTINCT patient_id, 2, `Enrollment Date`, 1, CreateDate, UUID()
	FROM openmrs.patient a
	INNER JOIN  openmrs.person b ON a.patient_id=b.person_id
	LEFT JOIN iqcare.rpt_patient c ON b.ptn_pk=c.ptn_pk
	LEFT JOIN iqcare.mst_patient d ON b.ptn_pk=d.ptn_pk
	WHERE !ISNULL(`Enrollment Date`)
	AND patient_id NOT IN
	(SELECT patient_id FROM openmrs.patient_program);
	
INSERT INTO openmrs.patient_program(patient_id, program_id, date_enrolled, creator, date_created, `uuid`)
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
	(encounter_type, patient_id, location_id, form_id, encounter_datetime, creator, date_created, visit_id, `uuid`, visit_pk)
	VALUES
	(7, NEW.patient_id, 2631, 9, NEW.date_started, 1, NEW.date_created, NEW.visit_id, UUID(), NEW.visit_pk);
END; //
DELIMITER ;

INSERT INTO openmrs.visit_type(`name`, creator, date_created, `uuid`)
	SELECT `Visit Type`, 1, NOW(), UUID() FROM iqcare.rpt_visittype;
	
INSERT INTO openmrs.visit(patient_id, visit_type_id, date_started, date_stopped, creator, date_created, `uuid`, visit_pk)
	SELECT person_id, IF(!ISNULL(visit_type_id), visit_type_id, 1), VisitDate, ADDTIME(VisitDate, '02:00:00'), 1, c.CreateDate, UUID(), visit_pk
	FROM openmrs.person a
	INNER JOIN iqcare.dtl_patientvitals b ON a.ptn_pk=b.ptn_pk
	INNER JOIN iqcare.ord_visit c ON b.visit_pk=c.visit_id
	INNER JOIN iqcare.rpt_visittype d ON c.VisitType=d.VisitTypeID
	INNER JOIN openmrs.visit_type e ON d.`Visit Type`=e.`name`;

INSERT INTO openmrs.visit(patient_id, visit_type_id, date_started, date_stopped, creator, date_created, ``uuid``, visit_pk)	
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
	(SELECT patientmastervisitid FROM iqcare.patientvitals)
	
	UNION SELECT person_id, 1, `start`, IF(!ISNULL(`end`), `end`, ADDTIME(`start`, '02:00:00')), 1, b.createdate, UUID(), a.patientmastervisitid + 9000000
	FROM iqcare.patientwhostage a
	INNER JOIN iqcare.patientmastervisit b ON a.patientmastervisitid=b.id
	INNER JOIN iqcare.patient c ON b.patientid=c.id
	INNER JOIN openmrs.person d ON c.ptn_pk=d.ptn_pk
	WHERE a.patientmastervisitid
	NOT IN
	(SELECT patientmastervisitid FROM iqcare.patientvitals)
	
	UNION SELECT person_id, 1, a.createdate, ADDTIME(a.createdate, '03:00:00'), 1, a.createdate, UUID(), patientmastervisitid + 11000000
	FROM iqcare.patientclinicalnotes a 
	INNER JOIN iqcare.patient b ON a.PatientId=b.id 
	INNER JOIN openmrs.person c ON b.ptn_pk=c.ptn_pk
	WHERE clinicalnotes <>'' AND
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
INSERT INTO openmrs.obs(person_id, concept_id, obs_datetime, location_id, value_coded, creator, date_created, `uuid`)
	SELECT DISTINCT patient_id, 1054, b.date_created, location_id, IF(`value`='', NULL, `value`), 1, b.date_created, UUID() 
	FROM openmrs.visit a INNER JOIN 
	(SELECT `value`, person_id, date_created FROM openmrs.person_attribute WHERE person_attribute_type_id = 5) b 
	ON a.patient_id=b.person_id;
	
-- #2 Patient temp
INSERT INTO openmrs.obs(person_id, concept_id, encounter_id, obs_datetime, location_id, value_numeric, creator, date_created, `uuid`)
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
INSERT INTO openmrs.obs(person_id, concept_id, encounter_id, obs_datetime, location_id, value_numeric, creator, date_created, `uuid`)
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
INSERT INTO openmrs.obs(person_id, concept_id, encounter_id, obs_datetime, location_id, value_numeric, creator, date_created, `uuid`)
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
INSERT INTO openmrs.obs(person_id, concept_id, encounter_id, obs_datetime, location_id, value_numeric, creator, date_created, `uuid`)
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
INSERT INTO openmrs.obs(person_id, concept_id, encounter_id, obs_datetime, location_id, value_numeric, creator, date_created, `uuid`)
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
INSERT INTO openmrs.encounter (encounter_type, patient_id, form_id, encounter_datetime, creator, date_created, `uuid`)
	SELECT DISTINCT 12, patient_id, 20, IFNULL(`Enrollment Date`, `CreateDate`), 1, CreateDate, UUID()
	FROM openmrs.patient a
	INNER JOIN  openmrs.person b ON a.patient_id=b.person_id
	LEFT JOIN iqcare.rpt_patient c ON b.ptn_pk=c.ptn_pk
	LEFT JOIN iqcare.mst_patient d ON b.ptn_pk=d.ptn_pk
	WHERE !ISNULL(b.ptn_pk);
   
-- #7 Patient WHO Stage
INSERT INTO openmrs.obs(person_id, concept_id, encounter_id, obs_datetime, location_id, value_coded, creator, date_created, `uuid`)
	SELECT patient_id, 5356, encounter_id, date_created, location_id, 
	IF(c.`WHOStage`='T1', 1204,
	IF(c.`WHOStage`='1', 1204,
	IF(c.`WHOStage`='T2', 1205,
	IF(c.`WHOStage`='2', 1205,
	IF(c.`WHOStage`='T3', 1206,
	IF(c.`WHOStage`='3', 1206,
	IF(c.`WHOStage`='T4', 1207,
	IF(c.`WHOStage`='4', 1207, NULL)))))))), 1, date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.dtl_patientstage b ON a.visit_pk=b.visit_pk
	INNER JOIN iqcare.rpt_whostage c ON b.whostage=c.id
	WHERE !ISNULL(`c`.`WHOStage`) AND `c`.`WHOStage`<>'0' AND `c`.`WHOStage`<>''
	
	UNION SELECT patient_id, 5356, encounter_id, e.date_created, location_id,
	IF(`WHOStage`=132, 1204,
	IF(`WHOStage`=133, 1205,
	IF(`WHOStage`=134, 1206,
	IF(`WHOStage`=135, 1207, NULL)))), 1, e.date_created, UUID()
	FROM iqcare.patientwhostage a
	INNER JOIN iqcare.patientmastervisit b ON a.patientmastervisitid=b.id
	INNER JOIN iqcare.patient c ON b.patientid=c.id
	INNER JOIN openmrs.person d ON c.ptn_pk=d.ptn_pk
	INNER JOIN openmrs.encounter e ON a.patientmastervisitid + 9000000 =e.visit_pk
	WHERE 
	e.encounter_datetime=b.createdate AND 
	patientmastervisitid 
	NOT IN 
	(SELECT patientmastervisitid FROM iqcare.patientvitals)
	
	UNION SELECT patient_id, 5356, encounter_id, c.date_created, location_id,
	IF(`WHOStage`=132, 1204,
	IF(`WHOStage`=133, 1205,
	IF(`WHOStage`=134, 1206,
	IF(`WHOStage`=135, 1207, NULL)))), 1, c.date_created, UUID()
	FROM iqcare.patientwhostage a
	INNER JOIN iqcare.patientvitals b ON a.patientmastervisitid=b.patientmastervisitid
	INNER JOIN openmrs.encounter c ON b.patientmastervisitid + 1000000=c.visit_pk
	WHERE b.visitdate=c.encounter_datetime
	GROUP BY a.id

	UNION SELECT patient_id, 5356, encounter_id, c.date_created, location_id,
	IF(`WHOStage`=132, 1204,
	IF(`WHOStage`=133, 1205,
	IF(`WHOStage`=134, 1206,
	IF(`WHOStage`=135, 1207, NULL)))), 1, c.date_created, UUID()
	FROM iqcare.patientwhostage a
	INNER JOIN iqcare.patientvitals b ON a.patientmastervisitid=b.patientmastervisitid
	INNER JOIN iqcare.patientmastervisit d ON b.patientmastervisitid=d.id 
	INNER JOIN openmrs.encounter c ON b.patientmastervisitid + 1000000=c.visit_pk
	WHERE d.`start`=c.encounter_datetime
	GROUP BY a.id;

-- #8 CD4 Count
INSERT INTO openmrs.obs(person_id, concept_id, encounter_id, obs_datetime, location_id, value_numeric, creator, date_created, `uuid`)
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
INSERT INTO openmrs.obs(person_id, concept_id, encounter_id, obs_datetime, location_id, value_numeric, creator, date_created, `uuid`)
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
INSERT INTO openmrs.obs(person_id, concept_id, encounter_id, obs_datetime, location_id, value_numeric, creator, date_created, `uuid`)
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
INSERT INTO openmrs.obs(person_id, concept_id, encounter_id, obs_datetime, location_id, value_numeric, creator, date_created, `uuid`)
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
INSERT INTO openmrs.obs(person_id, concept_id, encounter_id, obs_datetime, location_id, value_numeric, creator, date_created, `uuid`)
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
INSERT INTO openmrs.obs(person_id, concept_id, encounter_id, obs_datetime, location_id, value_numeric, creator, date_created, `uuid`)
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
INSERT INTO openmrs.obs(person_id, concept_id, encounter_id, obs_datetime, location_id, value_numeric, creator, date_created, `uuid`)
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
INSERT INTO openmrs.obs(person_id, concept_id, encounter_id, obs_datetime, location_id, value_numeric, creator, date_created, `uuid`)
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
	
	UNION SELECT patient_id, 5219, encounter_id, c.date_created, location_id, 5622, 1, c.date_created, UUID()
	FROM iqcare.complaintshistory a 
	INNER JOIN iqcare.patientvitals b ON a.patientmastervisitid=b.patientmastervisitid
	INNER JOIN openmrs.encounter c ON b.patientmastervisitid + 1000000=c.visit_pk
	WHERE b.visitdate=c.encounter_datetime AND
    presentingcomplaint <>''
	GROUP BY a.id
	
	UNION SELECT patient_id, 5219, encounter_id, c.date_created, location_id, 5622, 1, c.date_created, UUID()
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
	WHERE presentingcomplaint <>'' 
	AND d.encounter_datetime=a.createdate 
	AND patientmastervisitid 
	NOT IN 
	(SELECT patientmastervisitid FROM iqcare.patientvitals)
	
	UNION SELECT patient_id, 160430, encounter_id, c.date_created, location_id, presentingcomplaint, 1, c.date_created, UUID()
	FROM iqcare.complaintshistory a 
	INNER JOIN iqcare.patientvitals b ON a.patientmastervisitid=b.patientmastervisitid
	INNER JOIN openmrs.encounter c ON b.patientmastervisitid + 1000000=c.visit_pk
	WHERE b.visitdate=c.encounter_datetime
	AND presentingcomplaint <>''
	GROUP BY a.id
	
	UNION SELECT patient_id, 160430, encounter_id, c.date_created, location_id, presentingcomplaint, 1, c.date_created, UUID()
	FROM iqcare.complaintshistory a 
	INNER JOIN iqcare.patientvitals b ON a.patientmastervisitid=b.patientmastervisitid
	INNER JOIN iqcare.patientmastervisit d ON b.patientmastervisitid=d.id 
	INNER JOIN openmrs.encounter c ON b.patientmastervisitid + 1000000=c.visit_pk
	WHERE d.`start`=c.encounter_datetime 
	AND presentingcomplaint <>''
	GROUP BY a.id;

-- #21 Lab
--- lab encounter
INSERT INTO openmrs.encounter (encounter_type, patient_id, location_id, encounter_datetime, creator, date_created, `uuid`, visit_pk)
	SELECT 30, person_id, 2631, orderdate, 1, b.createdate, UUID(), visitid + 7000000
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
	
-- #22 Patient Care Ending
INSERT INTO openmrs.encounter (encounter_type, patient_id, location_id, form_id, encounter_datetime, creator, date_created, `uuid`, visit_pk)
	SELECT 2, person_id, 2631, 26, exitdate, 1, c.createdate, UUID(), patientmastervisitid + 10000000
	FROM openmrs.person a
	INNER JOIN iqcare.patient b ON a.ptn_pk=b.ptn_pk
	INNER JOIN iqcare.patientcareending c ON b.id=c.patientid
	
	UNION SELECT 2, person_id, 2631, 26, careendeddate, 1, b.createdate, UUID(), visit_id + 14000000
	FROM openmrs.person a
	INNER JOIN iqcare.dtl_patientcareended b ON a.ptn_pk=b.ptn_pk
	INNER JOIN iqcare.ord_visit c ON b.ptn_pk=c.ptn_pk
	WHERE !ISNULL(patientexittext)
	AND b.ptn_pk NOT IN
	(SELECT ptn_pk FROM patient a INNER JOIN `patientcareending` b ON a.id=b.patientid)
	GROUP BY person_id;
	
INSERT INTO openmrs.obs (person_id, concept_id, encounter_id, obs_datetime, location_id, value_coded, creator,  date_created, `uuid`)
	SELECT patient_id, 161555, encounter_id, encounter_datetime, location_id,
	IF(`ExitReason`=263, 159492,
	IF(`ExitReason`=262, 160034,
	IF(`ExitReason`=544, 5240, NULL))), 1, createdate, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientcareending b ON a.visit_pk=b.patientmastervisitid + 10000000
	WHERE exitdate=encounter_datetime
	GROUP BY b.id
	
	UNION SELECT patient_id, 161555, encounter_id, encounter_datetime, location_id,
	IF(`PatientExitText`='Lost to follow-up', 5240,
	IF(`PatientExitText`='SELF TRANSFER OUT', 165370,
	IF(`PatientExitText`='Transfer out', 159492,
	IF(`PatientExitText`='Deceased', 160034,
	IF(`PatientExitText`='Discharged', 1692,
	IF(`PatientExitText`='PMTCT end', 1253, NULL)))))), 1, c.createdate, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.ord_visit b ON a.visit_pk=b.visit_id + 14000000
	INNER JOIN iqcare.dtl_patientcareended c ON b.ptn_pk=c.ptn_pk
	WHERE careendeddate=encounter_datetime
	GROUP BY b.visit_id;
	
INSERT INTO openmrs.obs (person_id, concept_id, encounter_id, obs_datetime, location_id, value_datetime, creator,  date_created, `uuid`)
	SELECT patient_id, 160649, encounter_id, encounter_datetime, location_id, exitdate, 1, createdate, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientcareending b ON a.visit_pk=b.patientmastervisitid + 10000000
	WHERE exitdate=encounter_datetime
	AND exitreason=263
	GROUP BY b.id
	
	UNION SELECT patient_id, 160649, encounter_id, encounter_datetime, location_id, careendeddate, 1, c.createdate, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.ord_visit b ON a.visit_pk=b.visit_id + 14000000
	INNER JOIN iqcare.dtl_patientcareended c ON b.ptn_pk=c.ptn_pk
	WHERE careendeddate=encounter_datetime
	AND PatientExitText='Transfer out'
	GROUP BY b.visit_id
	
	UNION SELECT patient_id, 1543, encounter_id, encounter_datetime, location_id, IF(!ISNULL(dateofdeath), dateofdeath, exitdate), 1, createdate, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientcareending b ON a.visit_pk=b.patientmastervisitid + 10000000
	WHERE exitdate=encounter_datetime
	AND exitreason=262
	GROUP BY b.id
	
	UNION SELECT patient_id, 1543, encounter_id, encounter_datetime, location_id, careendeddate, 1, c.createdate, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.ord_visit b ON a.visit_pk=b.visit_id + 14000000
	INNER JOIN iqcare.dtl_patientcareended c ON b.ptn_pk=c.ptn_pk
	WHERE careendeddate=encounter_datetime
	AND PatientExitText='Deceased'
	GROUP BY b.visit_id;
	
INSERT INTO openmrs.obs (person_id, concept_id, encounter_id, obs_datetime, location_id, value_text, creator,  date_created, `uuid`)
	SELECT patient_id, 159495, encounter_id, encounter_datetime, location_id, transferoutfacility, 1, createdate, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientcareending b ON a.visit_pk=b.patientmastervisitid + 10000000
	WHERE exitdate=encounter_datetime
	AND exitreason=263
	AND !ISNULL(transferoutfacility)
	GROUP BY b.id;
	
-- #23 Patient Clinical Notes
INSERT INTO openmrs.obs(person_id, concept_id, encounter_id, obs_datetime, location_id, value_text, creator, date_created, UUID)
	SELECT patient_id, 160430, encounter_id, d.date_created, location_id, clinicalnotes, 1, d.date_created, UUID()
	FROM iqcare.patientclinicalnotes a 
	INNER JOIN iqcare.patient b ON a.PatientId=b.id 
	INNER JOIN openmrs.person c ON b.ptn_pk=c.ptn_pk
	INNER JOIN openmrs.encounter d ON a.patientmastervisitid + 11000000 =d.visit_pk
	WHERE clinicalnotes <>'' 
	AND d.encounter_datetime=a.createdate 
	AND patientmastervisitid 
	NOT IN 
	(SELECT patientmastervisitid FROM iqcare.patientvitals)

	UNION SELECT patient_id, 160430, encounter_id, c.date_created, location_id, clinicalnotes, 1, c.date_created, UUID()
	FROM iqcare.patientclinicalnotes a 
	INNER JOIN iqcare.patientvitals b ON a.patientmastervisitid=b.patientmastervisitid
	INNER JOIN openmrs.encounter c ON b.patientmastervisitid + 1000000=c.visit_pk
	WHERE b.visitdate=c.encounter_datetime
	AND clinicalnotes <>''
	GROUP BY a.id
	
	UNION SELECT patient_id, 160430, encounter_id, c.date_created, location_id, clinicalnotes, 1, c.date_created, UUID()
	FROM iqcare.patientclinicalnotes a 
	INNER JOIN iqcare.patientvitals b ON a.patientmastervisitid=b.patientmastervisitid
	INNER JOIN iqcare.patientmastervisit d ON b.patientmastervisitid=d.id 
	INNER JOIN openmrs.encounter c ON b.patientmastervisitid + 1000000=c.visit_pk
	WHERE d.`start`=c.encounter_datetime 
	AND clinicalnotes <>''
	GROUP BY a.id;
	
-- #24 Patient Family Planning
INSERT INTO openmrs.encounter (encounter_type, patient_id, location_id, form_id, encounter_datetime, creator, date_created, `uuid`, visit_pk)
	SELECT 4, person_id, 2631, 3, visitdate, 1, c.createdate, UUID(), patientmastervisitid + 12000000
	FROM openmrs.person a
	INNER JOIN iqcare.patient b ON a.ptn_pk=b.ptn_pk
	INNER JOIN iqcare.patientfamilyplanning c ON b.id=c.patientid
    WHERE familyplanningstatusid<>0;
	
INSERT INTO openmrs.obs (person_id, concept_id, encounter_id, obs_datetime, location_id, value_coded, creator,  date_created, `uuid`)
	SELECT patient_id, 160653, encounter_id, encounter_datetime, location_id,
	IF(`FamilyPlanningStatusId`=1, 965,
	IF(`FamilyPlanningStatusId`=2, 160652,
	IF(`FamilyPlanningStatusId`=3, 1360, NULL))), 1, createdate, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientfamilyplanning b ON a.visit_pk=b.patientmastervisitid + 12000000
	WHERE visitdate=encounter_datetime
	AND familyplanningstatusid<>0
	GROUP BY b.id
	
	UNION SELECT patient_id, 160575, encounter_id, encounter_datetime, location_id,
	IF(`ReasonNotOnFPId`=113, 160571,
	IF(`ReasonNotOnFPId`=114, 160572,
	IF(`ReasonNotOnFPId`=115, 160573,
	IF(`ReasonNotOnFPId`=116, 1434, NULL)))), 1, createdate, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientfamilyplanning b ON a.visit_pk=b.patientmastervisitid + 12000000
	WHERE visitdate=encounter_datetime
	AND familyplanningstatusid=2
	AND reasonnotonfpid<>0
	GROUP BY b.id
	
	UNION SELECT patient_id, 374, encounter_id, encounter_datetime, location_id,
	IF(`FPMethodId`=4, 190,
	IF(`FPMethodId`=5, 160570,
	IF(`FPMethodId`=6, 780,
	IF(`FPMethodId`=7, 5279,
	IF(`FPMethodId`=8, 1359,
	IF(`FPMethodId`=9, 5275,
	IF(`FPMethodId`=10, 136163,
	IF(`FPMethodId`=11, 5278,
	IF(`FPMethodId`=12, 5277,
	IF(`FPMethodId`=13, 1472,
	IF(`FPMethodId`=14, 1489,
	IF(`FPMethodId`=15, 162332, NULL))))))))))))yea, 1, c.createdate, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientfamilyplanning b ON a.visit_pk=b.patientmastervisitid + 12000000
	INNER JOIN iqcare.patientfamilyplanningmethod c ON b.id=c.patientfpid
	WHERE visitdate=encounter_datetime
	GROUP BY c.id;

-- #25 Patient ICF
INSERT INTO openmrs.encounter (encounter_type, patient_id, location_id, form_id, encounter_datetime, creator, date_created, `uuid`, visit_pk)
	SELECT 13, person_id, 2631, 27, visitdate, 1, d.createdate, UUID(), patientmastervisitid + 13000000
	FROM openmrs.person a
	INNER JOIN iqcare.patient b ON a.ptn_pk=b.ptn_pk
	INNER JOIN iqcare.patientmastervisit c ON b.id=c.patientid
	INNER JOIN iqcare.patienticf d ON c.id=d.patientmastervisitid;
	
INSERT INTO openmrs.obs (person_id, concept_id, encounter_id, obs_datetime, location_id, creator,  date_created, `uuid`)
	SELECT patient_id, 160108, encounter_id, encounter_datetime, location_id, 1, date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patienticf b ON a.visit_pk=b.patientmastervisitid + 13000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	WHERE visitdate=encounter_datetime
	GROUP BY b.id;
	
INSERT INTO openmrs.obs (person_id, concept_id, encounter_id, obs_datetime, location_id, obs_group_id, value_coded, creator,  date_created, `uuid`)
	SELECT patient_id, 1729, a.encounter_id, encounter_datetime, a.location_id, obs_id,
	IF(`Cough`=0, 1066,
	IF(`Cough`=1, 159799, NULL)), 1, a.date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patienticf b ON a.visit_pk=b.patientmastervisitid + 13000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	INNER JOIN openmrs.obs d ON a.encounter_id=d.encounter_id
	WHERE visitdate=encounter_datetime
	GROUP BY b.id

	UNION SELECT patient_id, 1729, a.encounter_id, encounter_datetime, a.location_id, obs_id,
	IF(`Fever`=0, 1066,
	IF(`Fever`=1, 1494, NULL)), 1, a.date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patienticf b ON a.visit_pk=b.patientmastervisitid + 13000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	INNER JOIN openmrs.obs d ON a.encounter_id=d.encounter_id
	WHERE visitdate=encounter_datetime
	GROUP BY b.id

	UNION SELECT patient_id, 1729, a.encounter_id, encounter_datetime, a.location_id, obs_id,
	IF(`WeightLoss`=0, 1066,
	IF(`WeightLoss`=1, 832, NULL)), 1, a.date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patienticf b ON a.visit_pk=b.patientmastervisitid + 13000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	INNER JOIN openmrs.obs d ON a.encounter_id=d.encounter_id
	WHERE visitdate=encounter_datetime
	GROUP BY b.id

	UNION SELECT patient_id, 1729, a.encounter_id, encounter_datetime, a.location_id, obs_id,
	IF(`NightSweats`=0, 1066,
	IF(`NightSweats`=1, 133027, NULL)), 1, a.date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patienticf b ON a.visit_pk=b.patientmastervisitid + 13000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	INNER JOIN openmrs.obs d ON a.encounter_id=d.encounter_id
	WHERE visitdate=encounter_datetime
	GROUP BY b.id;
	
INSERT INTO openmrs.obs (person_id, concept_id, encounter_id, obs_datetime, location_id, value_coded, creator,  date_created, `uuid`)
	SELECT patient_id, 164948, encounter_id, encounter_datetime, location_id, 
    IF(`OnAntiTbDrugs`=0, 1066,
    IF(`OnAntiTbDrugs`=1, 1065, NULL)), 1, date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patienticf b ON a.visit_pk=b.patientmastervisitid + 13000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	WHERE visitdate=encounter_datetime
	GROUP BY b.id
	
	UNION SELECT patient_id, 164950, encounter_id, encounter_datetime, location_id, 
    IF(`EverBeenOnIpt`=0, 1066,
    IF(`EverBeenOnIpt`=1, 1065, NULL)), 1, date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patienticf b ON a.visit_pk=b.patientmastervisitid + 13000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	WHERE visitdate=encounter_datetime
    AND !ISNULL(EverBeenOnIpt)
	GROUP BY b.id
	
	UNION SELECT patient_id, 164949, encounter_id, encounter_datetime, location_id, 
    IF(`OnIpt`=0, 1066,
    IF(`OnIpt`=1, 1065, NULL)), 1, date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patienticf b ON a.visit_pk=b.patientmastervisitid + 13000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	WHERE visitdate=encounter_datetime
	GROUP BY b.id
	
	UNION SELECT patient_id, 162309, encounter_id, encounter_datetime, location_id,
	IF(`StartAntiTb`=0, 1066,
	IF(`StartAntiTb`=1, 1065, NULL)), 1, date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patienticfaction b ON a.visit_pk=b.patientmastervisitid + 13000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	WHERE visitdate=encounter_datetime
	GROUP BY b.id
    
    UNION SELECT patient_id, 162275, encounter_id, encounter_datetime, location_id,
	IF(`EvaluatedForIpt`=0, 1066,
	IF(`EvaluatedForIpt`=1, 1065, NULL)), 1, date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patienticfaction b ON a.visit_pk=b.patientmastervisitid + 13000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	WHERE visitdate=encounter_datetime
	GROUP BY b.id
    
    UNION SELECT patient_id, 163414, encounter_id, encounter_datetime, location_id,
	IF(`InvitationOfContacts`=0, 1066,
	IF(`InvitationOfContacts`=1, 1065, NULL)), 1, date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patienticfaction b ON a.visit_pk=b.patientmastervisitid + 13000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	WHERE visitdate=encounter_datetime
	GROUP BY b.id
    
    UNION SELECT patient_id, 1271, encounter_id, encounter_datetime, location_id,
	IF(`SputumSmear`=1797, 307, NULL), 1, date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patienticfaction b ON a.visit_pk=b.patientmastervisitid + 13000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	WHERE visitdate=encounter_datetime
	AND `SputumSmear` NOT IN (0,1,2,3,2264,1570)
	GROUP BY b.id

	UNION SELECT patient_id, 1271, encounter_id, encounter_datetime, location_id,
	IF(`ChestXray`=1797, 12, NULL), 1, date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patienticfaction b ON a.visit_pk=b.patientmastervisitid + 13000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	WHERE visitdate=encounter_datetime
	AND `ChestXray` NOT IN (0,1,2,3,2264,1570)
	GROUP BY b.id

	UNION SELECT patient_id, 1271, encounter_id, encounter_datetime, location_id,
	IF(`GeneXpert`=1797, 162202, NULL), 1, date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patienticfaction b ON a.visit_pk=b.patientmastervisitid + 13000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	WHERE visitdate=encounter_datetime
	AND `GeneXpert` NOT IN (0,1,2,3,2264,1570)
	GROUP BY b.id;
	
-- #26 Patient IPT Workup
INSERT INTO openmrs.encounter (encounter_type, patient_id, location_id, form_id, encounter_datetime, creator, date_created, `uuid`, visit_pk)
	SELECT 13, person_id, 2631, 27, visitdate, 1, d.createdate, UUID(), patientmastervisitid + 15000000
	FROM openmrs.person a
	INNER JOIN iqcare.patient b ON a.ptn_pk=b.ptn_pk
	INNER JOIN iqcare.patientmastervisit c ON b.id=c.patientid
	INNER JOIN iqcare.patientiptworkup d ON c.id=d.patientmastervisitid;
	
INSERT INTO openmrs.obs (person_id, concept_id, encounter_id, obs_datetime, location_id, creator,  date_created, `uuid`)
	SELECT patient_id, 1727, encounter_id, encounter_datetime, location_id, 1, date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientiptworkup b ON a.visit_pk=b.patientmastervisitid + 15000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	WHERE visitdate=encounter_datetime
	GROUP BY b.id;
	
INSERT INTO openmrs.obs (person_id, concept_id, encounter_id, obs_datetime, location_id, obs_group_id, value_coded, creator,  date_created, `uuid`)
	SELECT patient_id, 1729, a.encounter_id, encounter_datetime, a.location_id, obs_id,
	IF(`YellowColouredUrine`=0, 1066,
	IF(`YellowColouredUrine`=1, 162311, NULL)), 1, a.date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientiptworkup b ON a.visit_pk=b.patientmastervisitid + 15000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	INNER JOIN openmrs.obs d ON a.encounter_id=d.encounter_id
	WHERE visitdate=encounter_datetime
	GROUP BY b.id

	UNION SELECT patient_id, 1729, a.encounter_id, encounter_datetime, a.location_id, obs_id,
	IF(`Numbness`=0, 1066,
	IF(`Numbness`=1, 132652, NULL)), 1, a.date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientiptworkup b ON a.visit_pk=b.patientmastervisitid + 15000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	INNER JOIN openmrs.obs d ON a.encounter_id=d.encounter_id
	WHERE visitdate=encounter_datetime
	GROUP BY b.id

	UNION SELECT patient_id, 1729, a.encounter_id, encounter_datetime, a.location_id, obs_id,
	IF(`YellownessOfEyes`=0, 1066,
	IF(`YellownessOfEyes`=1, 5192, NULL)), 1, a.date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientiptworkup b ON a.visit_pk=b.patientmastervisitid + 15000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	INNER JOIN openmrs.obs d ON a.encounter_id=d.encounter_id
	WHERE visitdate=encounter_datetime
	GROUP BY b.id

	UNION SELECT patient_id, 1729, a.encounter_id, encounter_datetime, a.location_id, obs_id,
	IF(`AbdominalTenderness`=0, 1066,
	IF(`AbdominalTenderness`=1, 124994, NULL)), 1, a.date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientiptworkup b ON a.visit_pk=b.patientmastervisitid + 15000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	INNER JOIN openmrs.obs d ON a.encounter_id=d.encounter_id
	WHERE visitdate=encounter_datetime
	GROUP BY b.id;
	
-- #27 Patient IPT
INSERT INTO openmrs.encounter (encounter_type, patient_id, location_id, form_id, encounter_datetime, creator, date_created, `uuid`, visit_pk)
	SELECT 18, person_id, 2631, 31, IFNULL(iptstartdate, c.createdate), 1, c.createdate, UUID(), patientmastervisitid + 16000000
	FROM openmrs.person a
	INNER JOIN iqcare.patient b ON a.ptn_pk=b.ptn_pk
	INNER JOIN iqcare.patientiptworkup c ON b.id=c.patientid
	WHERE startipt=1
	GROUP BY person_id;
	
INSERT INTO openmrs.obs(person_id, concept_id, encounter_id, obs_datetime, location_id, value_coded, creator, date_created, `uuid`)
	SELECT patient_id, 162276, encounter_id, encounter_datetime, location_id, 138571, 1, createdate, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientiptworkup b ON a.visit_pk=b.patientmastervisitid + 16000000
	WHERE encounter_datetime=IFNULL(iptstartdate, createdate)
	AND startipt=1
	GROUP BY patient_id;
	
INSERT INTO openmrs.encounter (encounter_type, patient_id, location_id, form_id, encounter_datetime, creator, date_created, `uuid`, visit_pk)
	SELECT 20, person_id, 2631, 33, visitdate, 1, d.createdate, UUID(), d.patientmastervisitid + 17000000
	FROM openmrs.person a
	INNER JOIN iqcare.patient b ON a.ptn_pk=b.ptn_pk
	INNER JOIN iqcare.patientmastervisit c ON b.id=c.patientid
	INNER JOIN iqcare.patientipt d ON c.id=d.patientmastervisitid;
	
INSERT INTO openmrs.obs(person_id, concept_id, encounter_id, obs_datetime, location_id, value_coded, creator, date_created, `uuid`)
	SELECT patient_id, 159098, encounter_id, encounter_datetime, location_id,
	IF(`Hepatotoxicity`=0, 1066,
	IF(`Hepatotoxicity`=1, 1065, NULL)), 1, b.createdate, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientipt b ON a.visit_pk=b.patientmastervisitid + 17000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	WHERE encounter_datetime=visitdate
	GROUP BY b.id

	UNION SELECT patient_id, 118983, encounter_id, encounter_datetime, location_id,
	IF(`Peripheralneoropathy`=0, 1066,
	IF(`Peripheralneoropathy`=1, 1065, NULL)), 1, b.createdate, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientipt b ON a.visit_pk=b.patientmastervisitid + 17000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	WHERE encounter_datetime=visitdate
	GROUP BY b.id

	UNION SELECT patient_id, 512, encounter_id, encounter_datetime, location_id,
	IF(`Rash`=0, 1066,
	IF(`Rash`=1, 1065, NULL)), 1, b.createdate, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientipt b ON a.visit_pk=b.patientmastervisitid + 17000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	WHERE encounter_datetime=visitdate
	GROUP BY b.id

	UNION SELECT patient_id, 164075, encounter_id, encounter_datetime, location_id,
	IF(`AdheranceMeasurement`=548, 159405,
	IF(`AdheranceMeasurement`=549, 159406,
	IF(`AdheranceMeasurement`=550, 159407, NULL))), 1, b.createdate, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientipt b ON a.visit_pk=b.patientmastervisitid + 17000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	WHERE `AdheranceMeasurement`<>0
	AND encounter_datetime=visitdate
	GROUP BY b.id;
	
INSERT INTO openmrs.obs(person_id, concept_id, encounter_id, obs_datetime, location_id, value_datetime, creator, date_created, `uuid`)
	SELECT patient_id, 164073, encounter_id, encounter_datetime, location_id, IptDueDate, 1, b.createdate, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientipt b ON a.visit_pk=b.patientmastervisitid + 17000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	WHERE encounter_datetime=visitdate
	GROUP BY b.id

	UNION SELECT patient_id, 164074, encounter_id, encounter_datetime, location_id, IptDateCollected, 1, b.createdate, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientipt b ON a.visit_pk=b.patientmastervisitid + 17000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	WHERE encounter_datetime=visitdate
	GROUP BY b.id;
	
INSERT INTO openmrs.obs(person_id, concept_id, encounter_id, obs_datetime, location_id, value_text, creator, date_created, `uuid`)
	SELECT patient_id, 160632, encounter_id, encounter_datetime, location_id, HepatotoxicityAction, 1, b.createdate, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientipt b ON a.visit_pk=b.patientmastervisitid + 17000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	WHERE HepatotoxicityAction<>''
	AND encounter_datetime=visitdate
	GROUP BY b.id

	UNION SELECT patient_id, 160632, encounter_id, encounter_datetime, location_id, PeripheralneoropathyAction, 1, b.createdate, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientipt b ON a.visit_pk=b.patientmastervisitid + 17000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	WHERE PeripheralneoropathyAction<>''
	AND encounter_datetime=visitdate
	GROUP BY b.id

	UNION SELECT patient_id, 160632, encounter_id, encounter_datetime, location_id, RashAction, 1, b.createdate, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientipt b ON a.visit_pk=b.patientmastervisitid + 17000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	WHERE RashAction<>''
	AND encounter_datetime=visitdate
	GROUP BY b.id

	UNION SELECT patient_id, 160632, encounter_id, encounter_datetime, location_id, AdheranceMeasurementAction, 1, b.createdate, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientipt b ON a.visit_pk=b.patientmastervisitid + 17000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	WHERE AdheranceMeasurementAction<>''
	AND encounter_datetime=visitdate
	GROUP BY b.id;
	
-- #28 Patient IPT Outcome
INSERT INTO openmrs.encounter (encounter_type, patient_id, location_id, form_id, encounter_datetime, creator, date_created, `uuid`, visit_pk)
	SELECT 19, person_id, 2631, 32, c.createdate, 1, c.createdate, UUID(), patientmastervisitid + 18000000
	FROM openmrs.person a
	INNER JOIN iqcare.patient b ON a.ptn_pk=b.ptn_pk
	INNER JOIN iqcare.patientiptoutcome c ON b.id=c.patientid
	WHERE iptevent=1;
	
INSERT INTO openmrs.obs(person_id, concept_id, encounter_id, obs_datetime, location_id, value_coded, creator, date_created, `uuid`)
	SELECT patient_id, 161555, encounter_id, encounter_datetime, location_id, 159836, 1, createdate, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientiptoutcome b ON a.visit_pk=b.patientmastervisitid + 18000000
	WHERE encounter_datetime = createdate
	AND iptevent = 1
	GROUP BY b.id;
	
-- #29 Patient Psychosocial Criteria
--- PsC
INSERT INTO openmrs.encounter (encounter_type, patient_id, location_id, form_id, encounter_datetime, creator, date_created, `uuid`, visit_pk)
	SELECT 13, person_id, 2631, 47, visitdate, 1, d.createdate, UUID(), patientmastervisitid + 19000000
	FROM openmrs.person a
	INNER JOIN iqcare.patient b ON a.ptn_pk=b.ptn_pk
	INNER JOIN iqcare.patientmastervisit c ON b.id=c.patientid
	INNER JOIN iqcare.patientpsychosocialcriteria d ON c.id=d.patientmastervisitid;
    
INSERT INTO openmrs.obs (person_id, concept_id, encounter_id, obs_datetime, location_id, creator,  date_created, `uuid`)
	SELECT patient_id, 160525, encounter_id, encounter_datetime, location_id, 1, date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientpsychosocialcriteria b ON a.visit_pk=b.patientmastervisitid + 19000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	WHERE visitdate=encounter_datetime
	GROUP BY b.id;
    
INSERT INTO openmrs.obs (person_id, concept_id, encounter_id, obs_datetime, location_id, obs_group_id, value_coded, creator,  date_created, `uuid`)
	SELECT patient_id, 1729, a.encounter_id, encounter_datetime, a.location_id, obs_id,
	IF(`BenefitART`=0, 1066,
	IF(`BenefitART`=1, 1065, NULL)), 1, a.date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientpsychosocialcriteria b ON a.visit_pk=b.patientmastervisitid + 19000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	INNER JOIN openmrs.obs d ON a.encounter_id=d.encounter_id
	WHERE visitdate=encounter_datetime
	GROUP BY b.id

	UNION SELECT patient_id, 160246, a.encounter_id, encounter_datetime, a.location_id, obs_id,
	IF(`Alcohol`=0, 1066,
	IF(`Alcohol`=1, 1065, NULL)), 1, a.date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientpsychosocialcriteria b ON a.visit_pk=b.patientmastervisitid + 19000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	INNER JOIN openmrs.obs d ON a.encounter_id=d.encounter_id
	WHERE visitdate=encounter_datetime
	GROUP BY b.id

	UNION SELECT patient_id, 159891, a.encounter_id, encounter_datetime, a.location_id, obs_id,
	IF(`Depression`=0, 1066,
	IF(`Depression`=1, 1065, NULL)), 1, a.date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientpsychosocialcriteria b ON a.visit_pk=b.patientmastervisitid + 19000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	INNER JOIN openmrs.obs d ON a.encounter_id=d.encounter_id
	WHERE visitdate=encounter_datetime
	GROUP BY b.id

	UNION SELECT patient_id, 1048, a.encounter_id, encounter_datetime, a.location_id, obs_id,
	IF(`Disclosure`=0, 2,
	IF(`Disclosure`=1, 1, NULL)), 1, a.date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientpsychosocialcriteria b ON a.visit_pk=b.patientmastervisitid + 19000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	INNER JOIN openmrs.obs d ON a.encounter_id=d.encounter_id
	WHERE visitdate=encounter_datetime
	GROUP BY b.id

	UNION SELECT patient_id, 164425, a.encounter_id, encounter_datetime, a.location_id, obs_id,
	IF(`AdministerART`=0, 1066,
	IF(`AdministerART`=1, 1065, NULL)), 1, a.date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientpsychosocialcriteria b ON a.visit_pk=b.patientmastervisitid + 19000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	INNER JOIN openmrs.obs d ON a.encounter_id=d.encounter_id
	WHERE visitdate=encounter_datetime
	GROUP BY b.id

	UNION SELECT patient_id, 121764, a.encounter_id, encounter_datetime, a.location_id, obs_id,
	IF(`effectsART`=0, 2,
	IF(`effectsART`=1, 1, NULL)), 1, a.date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientpsychosocialcriteria b ON a.visit_pk=b.patientmastervisitid + 19000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	INNER JOIN openmrs.obs d ON a.encounter_id=d.encounter_id
	WHERE visitdate=encounter_datetime
	GROUP BY b.id

	UNION SELECT patient_id, 5619, a.encounter_id, encounter_datetime, a.location_id, obs_id,
	IF(`dependents`=0, 1066,
	IF(`dependents`=1, 1065, NULL)), 1, a.date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientpsychosocialcriteria b ON a.visit_pk=b.patientmastervisitid + 19000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	INNER JOIN openmrs.obs d ON a.encounter_id=d.encounter_id
	WHERE visitdate=encounter_datetime
	GROUP BY b.id

	UNION SELECT patient_id, 159707, a.encounter_id, encounter_datetime, a.location_id, obs_id,
	IF(`AdherenceBarriers`=0, 1066,
	IF(`AdherenceBarriers`=1, 1065, NULL)), 1, a.date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientpsychosocialcriteria b ON a.visit_pk=b.patientmastervisitid + 19000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	INNER JOIN openmrs.obs d ON a.encounter_id=d.encounter_id
	WHERE visitdate=encounter_datetime
	GROUP BY b.id

	UNION SELECT patient_id, 163089, a.encounter_id, encounter_datetime, a.location_id, obs_id,
	IF(`AccurateLocator`=0, 1066,
	IF(`AccurateLocator`=1, 1065, NULL)), 1, a.date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientpsychosocialcriteria b ON a.visit_pk=b.patientmastervisitid + 19000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	INNER JOIN openmrs.obs d ON a.encounter_id=d.encounter_id
	WHERE visitdate=encounter_datetime
	GROUP BY b.id

	UNION SELECT patient_id, 162695, a.encounter_id, encounter_datetime, a.location_id, obs_id,
	IF(`StartART`=0, 1066,
	IF(`StartART`=1, 1065, NULL)), 1, a.date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientpsychosocialcriteria b ON a.visit_pk=b.patientmastervisitid + 19000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	INNER JOIN openmrs.obs d ON a.encounter_id=d.encounter_id
	WHERE visitdate=encounter_datetime
	GROUP BY b.id;
	
--- SSC
INSERT INTO openmrs.encounter (encounter_type, patient_id, location_id, form_id, encounter_datetime, creator, date_created, `uuid`, visit_pk)
	SELECT 13, person_id, 2631, 47, visitdate, 1, d.createdate, UUID(), patientmastervisitid + 20000000
	FROM openmrs.person a
	INNER JOIN iqcare.patient b ON a.ptn_pk=b.ptn_pk
	INNER JOIN iqcare.patientmastervisit c ON b.id=c.patientid
	INNER JOIN iqcare.patientsupportsystemcriteria d ON c.id=d.patientmastervisitid;
    
INSERT INTO openmrs.obs (person_id, concept_id, encounter_id, obs_datetime, location_id, creator,  date_created, `uuid`)
	SELECT patient_id, 160525, encounter_id, encounter_datetime, location_id, 1, date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientsupportsystemcriteria b ON a.visit_pk=b.patientmastervisitid + 20000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	WHERE visitdate=encounter_datetime
	GROUP BY b.id;
    
INSERT INTO openmrs.obs (person_id, concept_id, encounter_id, obs_datetime, location_id, obs_group_id, value_coded, creator,  date_created, `uuid`)
	SELECT patient_id, 160119, a.encounter_id, encounter_datetime, a.location_id, obs_id,
	IF(`TakingART`=0, 1066,
	IF(`TakingART`=1, 1065, NULL)), 1, a.date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientsupportsystemcriteria b ON a.visit_pk=b.patientmastervisitid + 20000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	INNER JOIN openmrs.obs d ON a.encounter_id=d.encounter_id
	WHERE visitdate=encounter_datetime
	GROUP BY b.id

	UNION SELECT patient_id, 163766, a.encounter_id, encounter_datetime, a.location_id, obs_id,
	IF(`supportGroup`=0, 1066,
	IF(`supportGroup`=1, 1065, NULL)), 1, a.date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientsupportsystemcriteria b ON a.visit_pk=b.patientmastervisitid + 20000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	INNER JOIN openmrs.obs d ON a.encounter_id=d.encounter_id
	WHERE visitdate=encounter_datetime
	GROUP BY b.id

	UNION SELECT patient_id, 164886, a.encounter_id, encounter_datetime, a.location_id, obs_id,
	IF(`TSIdentified`=0, 1066,
	IF(`TSIdentified`=1, 1065, NULL)), 1, a.date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientsupportsystemcriteria b ON a.visit_pk=b.patientmastervisitid + 20000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	INNER JOIN openmrs.obs d ON a.encounter_id=d.encounter_id
	WHERE visitdate=encounter_datetime
	GROUP BY b.id

	UNION SELECT patient_id, 163164, a.encounter_id, encounter_datetime, a.location_id, obs_id,
	IF(`EnrollSMSReminder`=0, 1066,
	IF(`EnrollSMSReminder`=1, 1065, NULL)), 1, a.date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientsupportsystemcriteria b ON a.visit_pk=b.patientmastervisitid + 20000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	INNER JOIN openmrs.obs d ON a.encounter_id=d.encounter_id
	WHERE visitdate=encounter_datetime
	GROUP BY b.id
    
    UNION SELECT patient_id, 164360, a.encounter_id, encounter_datetime, a.location_id, obs_id,
	IF(`OtherSupportSystems`=0, 1066,
	IF(`OtherSupportSystems`=1, 1065, NULL)), 1, a.date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientsupportsystemcriteria b ON a.visit_pk=b.patientmastervisitid + 20000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	INNER JOIN openmrs.obs d ON a.encounter_id=d.encounter_id
	WHERE visitdate=encounter_datetime
	GROUP BY b.id;
	
-- #30 Patient Transfer in
INSERT INTO openmrs.encounter (encounter_type, patient_id, location_id, form_id, encounter_datetime, creator, date_created, `uuid`, visit_pk)
	SELECT 12, person_id, 2631, 20, visitdate, 1, d.createdate, UUID(), patientmastervisitid + 21000000
	FROM openmrs.person a
	INNER JOIN iqcare.patient b ON a.ptn_pk=b.ptn_pk
	INNER JOIN iqcare.patientmastervisit c ON b.id=c.patientid
	INNER JOIN iqcare.patienttransferin d ON c.id=d.patientmastervisitid;

INSERT INTO openmrs.obs (person_id, concept_id, encounter_id, obs_datetime, location_id, value_coded, creator,  date_created, `uuid`)
	SELECT patient_id, 164932, encounter_id, encounter_datetime, location_id, 160563, 1, b.createdate, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patienttransferin b ON a.visit_pk=b.patientmastervisitid + 21000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	WHERE visitdate=encounter_datetime
	
	UNION SELECT patient_id, 164855, encounter_id, encounter_datetime, location_id,
	IF(`CurrentTreatment`=136,1652, IF(`CurrentTreatment`=137,160124, IF(`CurrentTreatment`=138,164968, IF(`CurrentTreatment`=139,162565,
	IF(`CurrentTreatment`=140,164505, IF(`CurrentTreatment`=141,164512, IF(`CurrentTreatment`=142,164969, IF(`CurrentTreatment`=143,162201,
	IF(`CurrentTreatment`=146,162199, IF(`CurrentTreatment`=147,162563, IF(`CurrentTreatment`=148,164970, IF(`CurrentTreatment`=149,162561,
	IF(`CurrentTreatment`=150,164511, IF(`CurrentTreatment`=151,162201, IF(`CurrentTreatment`=152,164512, IF(`CurrentTreatment`=153,162200,
	IF(`CurrentTreatment`=168,1652, IF(`CurrentTreatment`=169,160124, IF(`CurrentTreatment`=170,162561, IF(`CurrentTreatment`=171,164511,
	IF(`CurrentTreatment`=173,162199, IF(`CurrentTreatment`=174,162563, IF(`CurrentTreatment`=175,162200, IF(`CurrentTreatment`=179,164505,
	IF(`CurrentTreatment`=180,162201, IF(`CurrentTreatment`=181,164512, IF(`CurrentTreatment`=182,162561, IF(`CurrentTreatment`=183,164511,
	IF(`CurrentTreatment`=184,162200, NULL))))))))))))))))))))))))))))), 1, b.createdate, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patienttransferin b ON a.visit_pk=b.patientmastervisitid + 21000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	WHERE visitdate=encounter_datetime
	AND `CurrentTreatment`<>518
	
-- **wild card union selection** --
	UNION SELECT patient_id, 164855, encounter_id, encounter_datetime, location_id,
	IF(`Start Regimen Desc`='TDF + 3TC + EFV', 164505, IF(`Start Regimen Desc`='TDF + 3TC + NVP', 162565,
	IF(`Start Regimen Desc`='AZT + 3TC + NVP', 1652, IF(`Start Regimen Desc`='AZT + 3TC + EFV', 160124,
	IF(`Start Regimen Desc`='TDF + 3TC + LPV/r', 162201, IF(`Start Regimen Desc`='AZT + 3TC + LPV/r', 162561,
	IF(`Start Regimen Desc`='AZT + 3TC + ATV/r', 164511, IF(`Start Regimen Desc`='D4T + 3TC + NVP', 792,
	IF(`Start Regimen Desc`='RAL+3TC+DRV+RTV+TDF', 165371, NULL))))))))), 1, b.createdate, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patienttransferin b ON a.visit_pk=b.patientmastervisitid + 21000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	INNER JOIN iqcare.patient d ON c.patientid=d.id
	INNER JOIN iqcare.tmp_patienttransferin e ON d.ptn_pk=e.ptn_pk
	WHERE visitdate=encounter_datetime
	AND `CurrentTreatment`=518
	AND `Start Regimen Desc`<>'OI Medicines';
	
INSERT INTO openmrs.obs (person_id, concept_id, encounter_id, obs_datetime, location_id, value_text, creator,  date_created, `uuid`)
	SELECT patient_id, 160535, encounter_id, encounter_datetime, location_id, FacilityFrom, 1, b.createdate, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patienttransferin b ON a.visit_pk=b.patientmastervisitid + 21000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	WHERE visitdate=encounter_datetime
	AND `FacilityFrom`<>'';
	
INSERT INTO openmrs.obs (person_id, concept_id, encounter_id, obs_datetime, location_id, value_datetime, creator,  date_created, `uuid`)
	SELECT patient_id, 160534, encounter_id, encounter_datetime, location_id, TransferInDate, 1, b.createdate, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patienttransferin b ON a.visit_pk=b.patientmastervisitid + 21000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	WHERE visitdate=encounter_datetime
	
	UNION SELECT patient_id, 160555, encounter_id, encounter_datetime, location_id, TreatmentStartDate, 1, b.createdate, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patienttransferin b ON a.visit_pk=b.patientmastervisitid + 21000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	WHERE visitdate=encounter_datetime;
	
-- #31 Patient Population
INSERT INTO openmrs.encounter (encounter_type, patient_id, location_id, form_id, encounter_datetime, creator, date_created, `uuid`, visit_pk)
	SELECT 13, person_id, 2631, 27, visitdate, 1, c.createdate, UUID(), d.id + 22000000
	FROM openmrs.person a
	INNER JOIN iqcare.patient b ON a.ptn_pk=b.ptn_pk
	INNER JOIN iqcare.patientpopulation c ON b.personid=c.personid
	INNER JOIN iqcare.patientmastervisit d ON b.id=d.patientid
	GROUP BY c.id;

INSERT INTO openmrs.obs (person_id, concept_id, encounter_id, obs_datetime, location_id, value_coded, creator,  date_created, `uuid`)
	SELECT patient_id, 164930, encounter_id, encounter_datetime, location_id,
	IF(`PopulationType`='General Population', 164928,
	IF(`PopulationType`='Key Population', 164929, NULL)), 1, date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientmastervisit b ON a.visit_pk=b.id + 22000000
	INNER JOIN iqcare.patient c ON b.patientid=c.id
	INNER JOIN iqcare.patientpopulation d ON c.personid=d.personid
	WHERE visitdate=encounter_datetime
	GROUP BY d.id

	UNION SELECT patient_id, 160581, encounter_id, encounter_datetime, location_id,
	IF(`PopulationCategory`=65, 160579,
	IF(`PopulationCategory`=66, 105, NULL)), 1, date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientmastervisit b ON a.visit_pk=b.id + 22000000
	INNER JOIN iqcare.patient c ON b.patientid=c.id
	INNER JOIN iqcare.patientpopulation d ON c.personid=d.personid
	WHERE visitdate=encounter_datetime
	AND `PopulationCategory`<>0
	GROUP BY d.id;
	
-- #32 Patient Appointment
INSERT INTO openmrs.encounter (encounter_type, patient_id, location_id, form_id, encounter_datetime, creator, date_created, `uuid`, visit_pk)
	SELECT 13, person_id, 2631, 27, visitdate, 1, d.createdate, UUID(), patientmastervisitid + 23000000
	FROM openmrs.person a
	INNER JOIN iqcare.patient b ON a.ptn_pk=b.ptn_pk
	INNER JOIN iqcare.patientmastervisit c ON b.id=c.patientid
	INNER JOIN iqcare.patientappointment d ON c.id=d.patientmastervisitid;

INSERT INTO openmrs.obs (person_id, concept_id, encounter_id, obs_datetime, location_id, value_coded, creator,  date_created, `uuid`)
	SELECT patient_id, 160288, encounter_id, encounter_datetime, location_id,
	IF(`ReasonId`=235, 160523,
	IF(`ReasonId`=236, 1283,
	IF(`ReasonId`=237, 165372,
	IF(`ReasonId`=238, 160521,
	IF(`ReasonId`=1907, 165373, NULL))))), 1, date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientappointment b ON a.visit_pk=b.patientmastervisitid + 23000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	WHERE encounter_datetime=visitdate
	GROUP BY b.id

	UNION SELECT patient_id, 164947, encounter_id, encounter_datetime, location_id,
	IF(`DifferentiatedCareId`=239, 164944,
	IF(`DifferentiatedCareId`=240, 164943,
	IF(`DifferentiatedCareId`=257, 164942, NULL))), 1, date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientappointment b ON a.visit_pk=b.patientmastervisitid + 23000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	WHERE encounter_datetime=visitdate
	GROUP BY b.id;

INSERT INTO openmrs.obs (person_id, concept_id, encounter_id, obs_datetime, location_id, value_datetime, creator,  date_created, `uuid`)
	SELECT patient_id, 5096, encounter_id, encounter_datetime, location_id, AppointmentDate, 1, date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientappointment b ON a.visit_pk=b.patientmastervisitid + 23000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	WHERE encounter_datetime=visitdate
	GROUP BY b.id;
	
-- #33 Patient Baseline Assessment
INSERT INTO openmrs.encounter (encounter_type, patient_id, location_id, form_id, encounter_datetime, creator, date_created, `uuid`, visit_pk)
	SELECT 12, person_id, 2631, 20, visitdate, 1, d.createdate, UUID(), patientmastervisitid + 24000000
	FROM openmrs.person a
	INNER JOIN iqcare.patient b ON a.ptn_pk=b.ptn_pk
	INNER JOIN iqcare.patientmastervisit c ON b.id=c.patientid
	INNER JOIN iqcare.patientbaselineassessment d ON c.id=d.patientmastervisitid;
	
INSERT INTO openmrs.obs (person_id, concept_id, encounter_id, obs_datetime, location_id, value_coded, creator,  date_created, `uuid`)
	SELECT patient_id, 6032, encounter_id, encounter_datetime, location_id,
	IF(`HBVInfected`=0, 1066,
	IF(`HBVInfected`=1, 1065, NULL)), 1, date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientbaselineassessment b ON a.visit_pk=b.patientmastervisitid + 24000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	WHERE encounter_datetime=visitdate
	GROUP BY b.id

	UNION SELECT patient_id, 5272, encounter_id, encounter_datetime, location_id,
	IF(`Pregnant`=0, 1066,
	IF(`Pregnant`=1, 1065, NULL)), 1, date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientbaselineassessment b ON a.visit_pk=b.patientmastervisitid + 24000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	WHERE encounter_datetime=visitdate
	GROUP BY b.id

	UNION SELECT patient_id, 164500, encounter_id, encounter_datetime, location_id,
	IF(`TBInfected`=0, 1066,
	IF(`TBInfected`=1, 1065, NULL)), 1, date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientbaselineassessment b ON a.visit_pk=b.patientmastervisitid + 24000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	WHERE encounter_datetime=visitdate
	GROUP BY b.id

	UNION SELECT patient_id, 5632, encounter_id, encounter_datetime, location_id,
	IF(`BreastFeeding`=0, 1066,
	IF(`BreastFeeding`=1, 1065, NULL)), 1, date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientbaselineassessment b ON a.visit_pk=b.patientmastervisitid + 24000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	WHERE encounter_datetime=visitdate
	GROUP BY b.id

	UNION SELECT patient_id, 5356, encounter_id, encounter_datetime, location_id,
	IF(`WHOStage`=132, 1204,
	IF(`WHOStage`=133, 1205,
	IF(`WHOStage`=134, 1206,
	IF(`WHOStage`=135, 1207, NULL)))), 1, date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientbaselineassessment b ON a.visit_pk=b.patientmastervisitid + 24000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	WHERE encounter_datetime=visitdate
	AND `WHOStage`<>518
	GROUP BY b.id;
	
INSERT INTO openmrs.obs (person_id, concept_id, encounter_id, obs_datetime, location_id, value_numeric, creator,  date_created, `uuid`)
	SELECT patient_id, 5497, encounter_id, encounter_datetime, location_id, CD4Count, 1, date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientbaselineassessment b ON a.visit_pk=b.patientmastervisitid + 24000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	WHERE encounter_datetime=visitdate
	AND !ISNULL(CD4Count)
	GROUP BY b.id

	UNION SELECT patient_id, 5089, encounter_id, encounter_datetime, location_id, Weight, 1, date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientbaselineassessment b ON a.visit_pk=b.patientmastervisitid + 24000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	WHERE encounter_datetime=visitdate
	GROUP BY b.id

	UNION SELECT patient_id, 5090, encounter_id, encounter_datetime, location_id, Height, 1, date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patientbaselineassessment b ON a.visit_pk=b.patientmastervisitid + 24000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	WHERE encounter_datetime=visitdate
	GROUP BY b.id;
	
-- #34 Patient HIV Diagnosis
INSERT INTO openmrs.encounter (encounter_type, patient_id, location_id, form_id, encounter_datetime, creator, date_created, `uuid`, visit_pk)
	SELECT 12, person_id, 2631, 20, visitdate, 1, d.createdate, UUID(), patientmastervisitid + 25000000
	FROM openmrs.person a
	INNER JOIN iqcare.patient b ON a.ptn_pk=b.ptn_pk
	INNER JOIN iqcare.patientmastervisit c ON b.id=c.patientid
	INNER JOIN iqcare.patienthivdiagnosis d ON c.id=d.patientmastervisitid;
	
INSERT INTO openmrs.obs (person_id, concept_id, encounter_id, obs_datetime, location_id, value_datetime, creator,  date_created, `uuid`)
	SELECT patient_id, 160554, encounter_id, encounter_datetime, location_id, HIVDiagnosisDate, 1, date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patienthivdiagnosis b ON a.visit_pk=b.patientmastervisitid + 25000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	WHERE encounter_datetime=visitdate
	AND !ISNULL(HIVDiagnosisDate)
	GROUP BY b.id

	UNION SELECT patient_id, 160555, encounter_id, encounter_datetime, location_id, EnrollmentDate, 1, date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patienthivdiagnosis b ON a.visit_pk=b.patientmastervisitid + 25000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	WHERE encounter_datetime=visitdate
	AND !ISNULL(EnrollmentDate)
	GROUP BY b.id

	UNION SELECT patient_id, 159599, encounter_id, encounter_datetime, location_id, ARTInitiationDate, 1, date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patienthivdiagnosis b ON a.visit_pk=b.patientmastervisitid + 25000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	WHERE encounter_datetime=visitdate
	AND !ISNULL(ARTInitiationDate)
	GROUP BY b.id;
	
INSERT INTO openmrs.obs (person_id, concept_id, encounter_id, obs_datetime, location_id, value_coded, creator,  date_created, `uuid`)
	SELECT patient_id, 5356, encounter_id, encounter_datetime, location_id,
	IF(`EnrollmentWHOStage`=132, 1204,
	IF(`EnrollmentWHOStage`=133, 1205,
	IF(`EnrollmentWHOStage`=134, 1206,
	IF(`EnrollmentWHOStage`=135, 1207, NULL)))), 1, date_created, UUID()
	FROM openmrs.encounter a
	INNER JOIN iqcare.patienthivdiagnosis b ON a.visit_pk=b.patientmastervisitid + 25000000
	INNER JOIN iqcare.patientmastervisit c ON b.patientmastervisitid=c.id
	WHERE encounter_datetime=visitdate
	AND `EnrollmentWHOStage`<>518
	GROUP BY b.id;
	
-- #35 Patient Screening


	
-- End of Obs

ALTER TABLE openmrs.person DROP COLUMN ptn_pk;
ALTER TABLE openmrs.encounter DROP COLUMN visit_pk;
ALTER TABLE openmrs.visit DROP COLUMN visit_pk;
ALTER TABLE openmrs.orders DROP COLUMN labresult_pk;

SET FOREIGN_KEY_CHECKS=1;