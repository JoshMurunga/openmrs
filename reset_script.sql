SET FOREIGN_KEY_CHECKS=0;

delete from openmrs.person;
delete from openmrs.person_address;
delete from openmrs.person_attribute;
delete from openmrs.patient;
delete from openmrs.patient_identifier;
delete from openmrs.person_name;
delete from openmrs.patient_program;
delete from openmrs.encounter;
delete from openmrs.visit_type;
delete from openmrs.visit;
delete from openmrs.obs;
delete from openmrs.orders;

ALTER TABLE `openmrs`.`person` AUTO_INCREMENT = 1 ;
ALTER TABLE `openmrs`.`person_address` AUTO_INCREMENT = 1 ;
ALTER TABLE `openmrs`.`person_attribute` AUTO_INCREMENT = 1 ;
ALTER TABLE `openmrs`.`patient` AUTO_INCREMENT = 1 ;
ALTER TABLE `openmrs`.`patient_identifier` AUTO_INCREMENT = 1 ;
ALTER TABLE `openmrs`.`person_name` AUTO_INCREMENT = 1 ;
ALTER TABLE `openmrs`.`patient_program` AUTO_INCREMENT = 1 ;
ALTER TABLE `openmrs`.`encounter` AUTO_INCREMENT = 1 ;
ALTER TABLE `openmrs`.`visit_type` AUTO_INCREMENT = 1 ;
ALTER TABLE `openmrs`.`visit` AUTO_INCREMENT = 1 ;
ALTER TABLE `openmrs`.`obs` AUTO_INCREMENT = 1 ;
ALTER TABLE `openmrs`.`orders` AUTO_INCREMENT = 1 ;