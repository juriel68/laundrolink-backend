-- MySQL dump 10.13  Distrib 8.0.36, for Win64 (x86_64)
--
-- Host: localhost    Database: laundrolink_db
-- ------------------------------------------------------
-- Server version	5.5.5-10.4.32-MariaDB

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `add_ons`
--

DROP TABLE IF EXISTS `add_ons`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `add_ons` (
  `AddOnID` int(11) NOT NULL AUTO_INCREMENT,
  `AddOnName` varchar(50) NOT NULL,
  PRIMARY KEY (`AddOnID`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `add_ons`
--

LOCK TABLES `add_ons` WRITE;
/*!40000 ALTER TABLE `add_ons` DISABLE KEYS */;
INSERT INTO `add_ons` VALUES (1,'Powder Detergent'),(2,'Liquid Detergent'),(3,'Stain Remover/Stain treatment'),(4,'Fabric Conditioner/Softener'),(5,'Dryer sheet');
/*!40000 ALTER TABLE `add_ons` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `conversations`
--

DROP TABLE IF EXISTS `conversations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `conversations` (
  `ConversationID` int(11) NOT NULL AUTO_INCREMENT,
  `Participant1_ID` varchar(10) NOT NULL,
  `Participant2_ID` varchar(10) NOT NULL,
  `UpdatedAt` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`ConversationID`),
  UNIQUE KEY `uq_conversation_participants` (`Participant1_ID`,`Participant2_ID`),
  KEY `fk_participant2_id` (`Participant2_ID`),
  CONSTRAINT `fk_participant1_id` FOREIGN KEY (`Participant1_ID`) REFERENCES `users` (`UserID`) ON DELETE CASCADE,
  CONSTRAINT `fk_participant2_id` FOREIGN KEY (`Participant2_ID`) REFERENCES `users` (`UserID`) ON DELETE CASCADE,
  CONSTRAINT `chk_participant_order` CHECK (`Participant1_ID` < `Participant2_ID`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `conversations`
--

LOCK TABLES `conversations` WRITE;
/*!40000 ALTER TABLE `conversations` DISABLE KEYS */;
INSERT INTO `conversations` VALUES (1,'C1','S1','2025-11-24 20:34:36');
/*!40000 ALTER TABLE `conversations` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `cust_credentials`
--

DROP TABLE IF EXISTS `cust_credentials`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `cust_credentials` (
  `CustID` varchar(10) NOT NULL,
  `google_id` varchar(255) DEFAULT NULL,
  `is_verified` tinyint(1) DEFAULT 0,
  `picture` text DEFAULT NULL,
  `provider` varchar(50) DEFAULT 'google',
  `paymentMethod` varchar(255) DEFAULT NULL,
  `gcash_payment_method_id` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`CustID`),
  UNIQUE KEY `google_id` (`google_id`),
  CONSTRAINT `fk_custcredentials_customer` FOREIGN KEY (`CustID`) REFERENCES `customers` (`CustID`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cust_credentials`
--

LOCK TABLES `cust_credentials` WRITE;
/*!40000 ALTER TABLE `cust_credentials` DISABLE KEYS */;
INSERT INTO `cust_credentials` VALUES ('C1','108123800582683307374',1,'https://res.cloudinary.com/dihmaok1f/image/upload/v1764027489/laundrolink_profiles/vlwzs4y0bjban3douhu1.jpg','google',NULL,NULL);
/*!40000 ALTER TABLE `cust_credentials` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `customer_ratings`
--

DROP TABLE IF EXISTS `customer_ratings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `customer_ratings` (
  `CustRateID` int(11) NOT NULL AUTO_INCREMENT,
  `OrderID` varchar(10) NOT NULL,
  `CustRating` decimal(2,1) NOT NULL,
  `CustComment` text DEFAULT NULL,
  PRIMARY KEY (`CustRateID`),
  KEY `fk_customerrating_order` (`OrderID`),
  CONSTRAINT `fk_customerrating_order` FOREIGN KEY (`OrderID`) REFERENCES `orders` (`OrderID`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `customer_ratings`
--

LOCK TABLES `customer_ratings` WRITE;
/*!40000 ALTER TABLE `customer_ratings` DISABLE KEYS */;
/*!40000 ALTER TABLE `customer_ratings` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `customers`
--

DROP TABLE IF EXISTS `customers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `customers` (
  `CustID` varchar(10) NOT NULL,
  `CustName` varchar(50) NOT NULL,
  `CustPhone` varchar(20) DEFAULT NULL,
  `CustAddress` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`CustID`),
  UNIQUE KEY `CustPhone` (`CustPhone`),
  CONSTRAINT `fk_customer_user` FOREIGN KEY (`CustID`) REFERENCES `users` (`UserID`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `customers`
--

LOCK TABLES `customers` WRITE;
/*!40000 ALTER TABLE `customers` DISABLE KEYS */;
INSERT INTO `customers` VALUES ('C1','GULANE, JHON JURIEL G.','09655526322','La Aldea Buena Mactan, Basak, Lapu-Lapu, Central Visayas, 6015, Philippines');
/*!40000 ALTER TABLE `customers` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `delivery_app`
--

DROP TABLE IF EXISTS `delivery_app`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `delivery_app` (
  `DlvryAppID` int(11) NOT NULL AUTO_INCREMENT,
  `DlvryAppName` varchar(100) NOT NULL,
  `AppBaseFare` decimal(10,2) NOT NULL,
  `AppBaseKm` int(11) NOT NULL,
  `AppDistanceRate` decimal(10,2) NOT NULL,
  PRIMARY KEY (`DlvryAppID`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `delivery_app`
--

LOCK TABLES `delivery_app` WRITE;
/*!40000 ALTER TABLE `delivery_app` DISABLE KEYS */;
INSERT INTO `delivery_app` VALUES (1,'Lalamove',50.00,5,10.00);
/*!40000 ALTER TABLE `delivery_app` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `delivery_booking_proofs`
--

DROP TABLE IF EXISTS `delivery_booking_proofs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `delivery_booking_proofs` (
  `ProofID` int(11) NOT NULL AUTO_INCREMENT,
  `OrderID` varchar(10) NOT NULL,
  `ImageUrl` text DEFAULT NULL,
  `UploadedAt` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`ProofID`),
  KEY `fk_booking_proof_order` (`OrderID`),
  CONSTRAINT `fk_booking_proof_order` FOREIGN KEY (`OrderID`) REFERENCES `orders` (`OrderID`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `delivery_booking_proofs`
--

LOCK TABLES `delivery_booking_proofs` WRITE;
/*!40000 ALTER TABLE `delivery_booking_proofs` DISABLE KEYS */;
/*!40000 ALTER TABLE `delivery_booking_proofs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `delivery_payments`
--

DROP TABLE IF EXISTS `delivery_payments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `delivery_payments` (
  `DlvryPayID` int(11) NOT NULL AUTO_INCREMENT,
  `OrderID` varchar(10) NOT NULL,
  `DlvryAmount` decimal(10,2) NOT NULL,
  `MethodID` int(11) DEFAULT NULL,
  `PaymentProofImage` text DEFAULT NULL,
  `DlvryPaymentStatus` varchar(20) DEFAULT NULL,
  `StatusUpdatedAt` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `CreatedAt` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`DlvryPayID`),
  KEY `fk_dlvry_pay_order` (`OrderID`),
  KEY `fk_delivery_payment` (`MethodID`),
  CONSTRAINT `fk_delivery_payment` FOREIGN KEY (`MethodID`) REFERENCES `payment_methods` (`MethodID`) ON DELETE CASCADE,
  CONSTRAINT `fk_dlvry_pay_order` FOREIGN KEY (`OrderID`) REFERENCES `orders` (`OrderID`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=18 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `delivery_payments`
--

LOCK TABLES `delivery_payments` WRITE;
/*!40000 ALTER TABLE `delivery_payments` DISABLE KEYS */;
INSERT INTO `delivery_payments` VALUES (2,'ODR5385839',71.00,NULL,NULL,'Pending Later','2025-11-23 08:57:30','2025-11-23 08:57:30'),(3,'ODR8739823',71.00,NULL,NULL,'Pending Later','2025-11-23 12:00:26','2025-11-23 12:00:26'),(4,'ODR4715425',142.00,NULL,NULL,'Unpaid','2025-11-23 12:33:23','2025-11-23 12:33:23'),(5,'ODR1574946',71.00,2,NULL,'Paid','2025-11-24 18:04:24','2025-11-23 12:55:38'),(6,'ODR6329506',142.00,1,NULL,'Paid','2025-11-24 23:22:04','2025-11-23 12:58:11'),(7,'ODR1731624',51.00,1,NULL,'To Confirm','2025-11-23 15:00:08','2025-11-23 13:19:59'),(8,'ODR1497733',51.00,NULL,NULL,'Pending Later','2025-11-23 13:23:06','2025-11-23 13:23:06'),(9,'ODR5247421',0.00,NULL,NULL,NULL,'2025-11-24 10:10:37','2025-11-24 10:10:37'),(10,'ODR4245326',0.00,NULL,NULL,NULL,'2025-11-24 10:36:06','2025-11-24 10:36:06'),(11,'ODR6655691',51.00,NULL,NULL,'Pending','2025-11-24 21:09:16','2025-11-24 10:37:21'),(12,'ODR3038915',51.00,1,NULL,'Paid','2025-11-24 23:22:52','2025-11-24 10:38:01'),(13,'ODR6673938',101.00,2,NULL,'Paid','2025-11-24 16:23:47','2025-11-24 10:39:30'),(14,'ODR5687837',71.00,NULL,NULL,'Pending','2025-11-24 21:06:31','2025-11-24 21:06:31'),(15,'ODR3707820',71.00,2,NULL,'Paid','2025-11-24 23:22:46','2025-11-24 22:27:11'),(16,'ODR1839335',71.00,NULL,NULL,'Pending Later','2025-11-24 22:28:05','2025-11-24 22:28:05'),(17,'ODR7394733',142.00,1,NULL,'Paid','2025-11-24 23:22:14','2025-11-24 23:05:51');
/*!40000 ALTER TABLE `delivery_payments` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `delivery_status`
--

DROP TABLE IF EXISTS `delivery_status`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `delivery_status` (
  `DlvryStatID` int(11) NOT NULL AUTO_INCREMENT,
  `OrderID` varchar(10) NOT NULL,
  `DlvryStatus` varchar(30) NOT NULL,
  `UpdatedAt` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`DlvryStatID`),
  KEY `fk_delivery_status_order` (`OrderID`),
  CONSTRAINT `fk_delivery_status_order` FOREIGN KEY (`OrderID`) REFERENCES `orders` (`OrderID`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `delivery_status`
--

LOCK TABLES `delivery_status` WRITE;
/*!40000 ALTER TABLE `delivery_status` DISABLE KEYS */;
INSERT INTO `delivery_status` VALUES (1,'ODR6673938','To Pick-up','2025-11-24 16:30:47'),(2,'ODR1574946','To Pick-up','2025-11-24 16:31:45'),(3,'ODR6673938','Arrived at Customer','2025-11-24 18:02:55'),(4,'ODR1574946','Staff Booked','2025-11-24 18:04:24'),(5,'ODR1574946','Delivered In Shop','2025-11-24 18:06:14'),(6,'ODR6329506','To Pick-up','2025-11-24 23:22:04'),(7,'ODR7394733','To Pick-up','2025-11-24 23:22:14'),(8,'ODR3707820','To Pick-up','2025-11-24 23:22:46'),(9,'ODR3038915','To Pick-up','2025-11-24 23:22:52');
/*!40000 ALTER TABLE `delivery_status` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `delivery_types`
--

DROP TABLE IF EXISTS `delivery_types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `delivery_types` (
  `DlvryTypeID` int(11) NOT NULL AUTO_INCREMENT,
  `DlvryTypeName` varchar(30) NOT NULL,
  PRIMARY KEY (`DlvryTypeID`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `delivery_types`
--

LOCK TABLES `delivery_types` WRITE;
/*!40000 ALTER TABLE `delivery_types` DISABLE KEYS */;
INSERT INTO `delivery_types` VALUES (1,'Drop-off Only'),(2,'Pick-up Only'),(3,'For Delivery'),(4,'Pick-up & Delivery');
/*!40000 ALTER TABLE `delivery_types` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `fabrics`
--

DROP TABLE IF EXISTS `fabrics`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `fabrics` (
  `FabID` int(11) NOT NULL AUTO_INCREMENT,
  `FabName` varchar(50) NOT NULL,
  PRIMARY KEY (`FabID`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `fabrics`
--

LOCK TABLES `fabrics` WRITE;
/*!40000 ALTER TABLE `fabrics` DISABLE KEYS */;
INSERT INTO `fabrics` VALUES (1,'Regular Clothes'),(2,'Blankets, bedsheets, towels, pillowcase'),(3,'Comforter');
/*!40000 ALTER TABLE `fabrics` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `invoices`
--

DROP TABLE IF EXISTS `invoices`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `invoices` (
  `InvoiceID` varchar(10) NOT NULL,
  `OrderID` varchar(10) NOT NULL,
  `MethodID` int(11) DEFAULT NULL,
  `PayAmount` decimal(10,2) NOT NULL,
  `ProofImage` text DEFAULT NULL,
  `PaymentStatus` varchar(20) DEFAULT NULL,
  `StatusUpdatedAt` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `PmtCreatedAt` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`InvoiceID`),
  KEY `fk_invoice_order` (`OrderID`),
  KEY `fk_invoice_method` (`MethodID`),
  CONSTRAINT `fk_invoice_method` FOREIGN KEY (`MethodID`) REFERENCES `payment_methods` (`MethodID`) ON DELETE CASCADE,
  CONSTRAINT `fk_invoice_order` FOREIGN KEY (`OrderID`) REFERENCES `orders` (`OrderID`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `invoices`
--

LOCK TABLES `invoices` WRITE;
/*!40000 ALTER TABLE `invoices` DISABLE KEYS */;
INSERT INTO `invoices` VALUES ('INV1120406','ODR8739823',NULL,0.00,NULL,'To Confirm','2025-11-23 12:00:26','2025-11-23 12:00:26'),('INV1906748','ODR3232437',NULL,0.00,NULL,'To Confirm','2025-11-23 12:21:37','2025-11-23 12:21:37'),('INV2354542','ODR1574946',NULL,0.00,NULL,'To Confirm','2025-11-23 12:55:38','2025-11-23 12:55:38'),('INV3607094','ODR5702849',NULL,0.00,NULL,'To Confirm','2025-11-23 12:01:12','2025-11-23 12:01:12'),('INV5310710','ODR4183791',NULL,0.00,NULL,'To Confirm','2025-11-23 08:00:07','2025-11-23 08:00:07'),('INV5495507','ODR6655691',NULL,433.50,NULL,'To Pay','2025-11-24 21:10:58','2025-11-24 21:10:58'),('INV5980321','ODR5687837',1,291.00,NULL,'To Confirm','2025-11-24 23:12:16','2025-11-24 21:08:04'),('INV6436330','ODR4715425',NULL,0.00,NULL,'To Confirm','2025-11-23 12:33:23','2025-11-23 12:33:23'),('INV6500473','ODR3722550',NULL,0.00,NULL,'To Confirm','2025-11-23 08:43:13','2025-11-23 08:43:13'),('INV6770696','ODR6329506',NULL,0.00,NULL,'To Confirm','2025-11-23 12:58:11','2025-11-23 12:58:11'),('INV7578656','ODR2356208',NULL,0.00,NULL,'To Confirm','2025-11-23 12:11:23','2025-11-23 12:11:23'),('INV8648665','ODR6898980',NULL,0.00,NULL,'To Confirm','2025-11-23 08:40:02','2025-11-23 08:40:02'),('INV8698371','ODR5385839',NULL,0.00,NULL,'To Confirm','2025-11-23 08:57:30','2025-11-23 08:57:30'),('INV8781925','ODR3919723',NULL,0.00,NULL,'To Confirm','2025-11-23 11:52:15','2025-11-23 11:52:15'),('INV9245635','ODR1669928',NULL,0.00,NULL,'To Confirm','2025-11-23 13:21:53','2025-11-23 13:21:53'),('INV9398837','ODR1731624',NULL,0.00,NULL,'To Confirm','2025-11-23 13:19:59','2025-11-23 13:19:59'),('INV9562127','ODR1497733',NULL,0.00,NULL,'To Confirm','2025-11-23 13:23:06','2025-11-23 13:23:06'),('INV9697896','ODR6673938',2,325.00,NULL,'Paid','2025-11-24 23:23:30','2025-11-24 20:55:14');
/*!40000 ALTER TABLE `invoices` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `laundry_details`
--

DROP TABLE IF EXISTS `laundry_details`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `laundry_details` (
  `LndryDtlID` int(11) NOT NULL AUTO_INCREMENT,
  `OrderID` varchar(10) NOT NULL,
  `SvcID` int(11) NOT NULL,
  `DlvryID` int(11) NOT NULL,
  `Kilogram` decimal(5,1) DEFAULT 0.0,
  `SpecialInstr` varchar(300) DEFAULT NULL,
  `WeightProofImage` text DEFAULT NULL,
  PRIMARY KEY (`LndryDtlID`),
  KEY `fk_laundrydetails_order` (`OrderID`),
  KEY `fk_order_service` (`SvcID`),
  KEY `fk_order_delivery` (`DlvryID`),
  CONSTRAINT `fk_laundrydetails_order` FOREIGN KEY (`OrderID`) REFERENCES `orders` (`OrderID`) ON DELETE CASCADE,
  CONSTRAINT `fk_order_delivery` FOREIGN KEY (`DlvryID`) REFERENCES `shop_delivery_options` (`DlvryID`) ON DELETE CASCADE,
  CONSTRAINT `fk_order_service` FOREIGN KEY (`SvcID`) REFERENCES `services` (`SvcID`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=31 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `laundry_details`
--

LOCK TABLES `laundry_details` WRITE;
/*!40000 ALTER TABLE `laundry_details` DISABLE KEYS */;
INSERT INTO `laundry_details` VALUES (3,'ODR4183791',2,3,0.0,NULL,NULL),(4,'ODR6898980',1,1,0.0,NULL,NULL),(5,'ODR3722550',3,3,0.0,'vguu',NULL),(7,'ODR5385839',2,3,0.0,NULL,NULL),(8,'ODR3919723',1,4,0.0,'gg',NULL),(9,'ODR8739823',1,3,0.0,NULL,NULL),(10,'ODR5702849',1,2,0.0,NULL,NULL),(11,'ODR2356208',5,4,0.0,'hyg',NULL),(12,'ODR3232437',1,4,0.0,'jggg',NULL),(13,'ODR4715425',1,4,0.0,NULL,NULL),(14,'ODR1574946',1,2,0.0,'gtt',NULL),(15,'ODR6329506',1,4,0.0,'gtt',NULL),(16,'ODR1731624',1,2,0.0,'jytg',NULL),(17,'ODR1669928',1,1,0.0,'jytg',NULL),(18,'ODR1497733',1,3,0.0,'gyg',NULL),(19,'ODR5247421',1,1,0.0,'bggh',NULL),(20,'ODR4245326',1,1,0.0,'bxhjd',NULL),(21,'ODR6655691',2,3,6.5,'gft','https://res.cloudinary.com/dihmaok1f/image/upload/v1764018657/laundrolink_weight_proofs/zkcdihzrsl0nek8aqfj3.jpg'),(22,'ODR3038915',3,2,0.0,NULL,NULL),(23,'ODR6673938',3,4,7.5,NULL,'https://res.cloudinary.com/dihmaok1f/image/upload/v1764017714/laundrolink_weight_proofs/bwfpabqsufmcei5anfkq.jpg'),(24,'ODR5687837',3,3,5.0,'jgtttdhi','https://res.cloudinary.com/dihmaok1f/image/upload/v1764018481/laundrolink_weight_proofs/birr2164k6bwxf559mlo.jpg'),(26,'ODR6306890',1,2,0.0,NULL,NULL),(27,'ODR3707820',1,2,0.0,NULL,NULL),(28,'ODR1839335',1,3,0.0,NULL,NULL),(29,'ODR7852487',1,1,0.0,NULL,NULL),(30,'ODR7394733',2,4,0.0,NULL,NULL);
/*!40000 ALTER TABLE `laundry_details` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `laundry_shops`
--

DROP TABLE IF EXISTS `laundry_shops`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `laundry_shops` (
  `ShopID` int(11) NOT NULL AUTO_INCREMENT,
  `OwnerID` varchar(10) DEFAULT NULL,
  `ShopName` varchar(100) NOT NULL,
  `ShopDescrp` varchar(300) DEFAULT NULL,
  `ShopAddress` varchar(100) DEFAULT NULL,
  `ShopPhone` varchar(15) DEFAULT NULL,
  `ShopOpeningHours` varchar(50) DEFAULT NULL,
  `ShopStatus` varchar(20) DEFAULT NULL,
  `DateCreated` timestamp NOT NULL DEFAULT current_timestamp(),
  `ShopImage_url` text DEFAULT NULL,
  PRIMARY KEY (`ShopID`),
  KEY `fk_laundryshop_owner` (`OwnerID`),
  CONSTRAINT `fk_laundryshop_owner` FOREIGN KEY (`OwnerID`) REFERENCES `shop_owners` (`OwnerID`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `laundry_shops`
--

LOCK TABLES `laundry_shops` WRITE;
/*!40000 ALTER TABLE `laundry_shops` DISABLE KEYS */;
INSERT INTO `laundry_shops` VALUES (1,'O1','Wash N\' Dry','Experience top-notch laundry facilities equipped with state-of-the-art machines and a clean, comfortable environment.','La Aldea Buena Mactan, Basak, Lapu-Lapu, Central Visayas, Philippines','09171234567','8:00am - 6:00pm','Available','2025-11-22 16:33:27',NULL);
/*!40000 ALTER TABLE `laundry_shops` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `messages`
--

DROP TABLE IF EXISTS `messages`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `messages` (
  `MessageID` int(11) NOT NULL AUTO_INCREMENT,
  `ConversationID` int(11) NOT NULL,
  `SenderID` varchar(10) NOT NULL,
  `ReceiverID` varchar(10) NOT NULL,
  `MessageText` text DEFAULT NULL,
  `MessageImage` text DEFAULT NULL,
  `MessageStatus` varchar(20) DEFAULT 'Sent',
  `CreatedAt` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`MessageID`),
  KEY `fk_message_conversation` (`ConversationID`),
  KEY `fk_message_sender` (`SenderID`),
  KEY `fk_message_receiver` (`ReceiverID`),
  CONSTRAINT `fk_message_conversation` FOREIGN KEY (`ConversationID`) REFERENCES `conversations` (`ConversationID`) ON DELETE CASCADE,
  CONSTRAINT `fk_message_receiver` FOREIGN KEY (`ReceiverID`) REFERENCES `users` (`UserID`) ON DELETE CASCADE,
  CONSTRAINT `fk_message_sender` FOREIGN KEY (`SenderID`) REFERENCES `users` (`UserID`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `messages`
--

LOCK TABLES `messages` WRITE;
/*!40000 ALTER TABLE `messages` DISABLE KEYS */;
INSERT INTO `messages` VALUES (1,1,'S1','C1','Weight has been updated, please proceed to payment.',NULL,'Sent','2025-11-24 20:34:36'),(2,1,'S1','C1','Weight has been updated, please proceed to payment.',NULL,'Sent','2025-11-24 20:55:14'),(3,1,'S1','C1','Weight has been updated, please proceed to payment.',NULL,'Sent','2025-11-24 21:08:04'),(4,1,'S1','C1','Weight has been updated, please proceed to payment.',NULL,'Sent','2025-11-24 21:10:58');
/*!40000 ALTER TABLE `messages` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `notifications`
--

DROP TABLE IF EXISTS `notifications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `notifications` (
  `NotificationID` int(11) NOT NULL AUTO_INCREMENT,
  `UserID` varchar(10) NOT NULL,
  `NotifType` varchar(50) NOT NULL,
  `NotifMessage` text NOT NULL,
  `NotifIsRead` tinyint(1) DEFAULT 0,
  `NotifCreatedAt` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`NotificationID`),
  KEY `fk_notification_user` (`UserID`),
  CONSTRAINT `fk_notification_user` FOREIGN KEY (`UserID`) REFERENCES `users` (`UserID`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `notifications`
--

LOCK TABLES `notifications` WRITE;
/*!40000 ALTER TABLE `notifications` DISABLE KEYS */;
/*!40000 ALTER TABLE `notifications` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `order_addons`
--

DROP TABLE IF EXISTS `order_addons`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `order_addons` (
  `LndryDtlID` int(11) NOT NULL,
  `AddOnID` int(11) NOT NULL,
  PRIMARY KEY (`LndryDtlID`,`AddOnID`),
  KEY `fk_orderaddons_addon` (`AddOnID`),
  CONSTRAINT `fk_orderaddons_addon` FOREIGN KEY (`AddOnID`) REFERENCES `add_ons` (`AddOnID`) ON DELETE CASCADE,
  CONSTRAINT `fk_orderaddons_laundrydetails` FOREIGN KEY (`LndryDtlID`) REFERENCES `laundry_details` (`LndryDtlID`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `order_addons`
--

LOCK TABLES `order_addons` WRITE;
/*!40000 ALTER TABLE `order_addons` DISABLE KEYS */;
INSERT INTO `order_addons` VALUES (3,1),(4,1),(4,2),(5,1),(5,3),(7,2),(8,2),(9,3),(10,1),(11,1),(11,2),(12,2),(13,2),(14,1),(15,1),(16,1),(16,3),(17,1),(17,3),(18,2),(19,1),(19,2),(19,3),(19,5),(20,1),(20,3),(21,2),(22,2),(23,2),(24,1),(26,1),(27,1),(28,1),(29,2),(30,2);
/*!40000 ALTER TABLE `order_addons` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `order_fabrics`
--

DROP TABLE IF EXISTS `order_fabrics`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `order_fabrics` (
  `LndryDtlID` int(11) NOT NULL,
  `FabID` int(11) NOT NULL,
  PRIMARY KEY (`LndryDtlID`,`FabID`),
  KEY `fk_orderfabric_fabrictype` (`FabID`),
  CONSTRAINT `fk_orderfabric_fabrictype` FOREIGN KEY (`FabID`) REFERENCES `fabrics` (`FabID`) ON DELETE CASCADE,
  CONSTRAINT `fk_orderfabric_laundrydetails` FOREIGN KEY (`LndryDtlID`) REFERENCES `laundry_details` (`LndryDtlID`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `order_fabrics`
--

LOCK TABLES `order_fabrics` WRITE;
/*!40000 ALTER TABLE `order_fabrics` DISABLE KEYS */;
INSERT INTO `order_fabrics` VALUES (3,2),(4,2),(5,1),(5,3),(7,3),(8,2),(9,2),(10,3),(11,2),(12,2),(13,3),(14,2),(15,2),(16,2),(17,2),(18,2),(19,1),(19,2),(19,3),(20,2),(21,2),(22,2),(22,3),(23,2),(23,3),(24,1),(24,3),(26,2),(27,2),(28,2),(29,2),(30,2);
/*!40000 ALTER TABLE `order_fabrics` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `order_processing`
--

DROP TABLE IF EXISTS `order_processing`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `order_processing` (
  `OrderProcID` int(11) NOT NULL AUTO_INCREMENT,
  `OrderID` varchar(10) NOT NULL,
  `OrderProcStatus` varchar(30) NOT NULL,
  `OrderProcUpdatedAt` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`OrderProcID`),
  KEY `fk_orderprocessing_order` (`OrderID`),
  CONSTRAINT `fk_orderprocessing_order` FOREIGN KEY (`OrderID`) REFERENCES `orders` (`OrderID`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `order_processing`
--

LOCK TABLES `order_processing` WRITE;
/*!40000 ALTER TABLE `order_processing` DISABLE KEYS */;
INSERT INTO `order_processing` VALUES (1,'ODR6673938','Washing','2025-11-24 23:25:34'),(2,'ODR6673938','Drying','2025-11-24 23:25:55'),(3,'ODR6673938','Folding','2025-11-24 23:26:20');
/*!40000 ALTER TABLE `order_processing` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `order_status`
--

DROP TABLE IF EXISTS `order_status`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `order_status` (
  `OrderStatID` int(11) NOT NULL AUTO_INCREMENT,
  `OrderID` varchar(10) NOT NULL,
  `OrderStatus` varchar(20) DEFAULT NULL,
  `OrderUpdatedAt` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`OrderStatID`),
  KEY `fk_orderstatus_order` (`OrderID`),
  CONSTRAINT `fk_orderstatus_order` FOREIGN KEY (`OrderID`) REFERENCES `orders` (`OrderID`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=34 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `order_status`
--

LOCK TABLES `order_status` WRITE;
/*!40000 ALTER TABLE `order_status` DISABLE KEYS */;
INSERT INTO `order_status` VALUES (3,'ODR4183791','0','2025-11-23 08:00:07'),(4,'ODR6898980','0','2025-11-23 08:40:02'),(5,'ODR3722550','0','2025-11-23 08:43:13'),(7,'ODR5385839','0','2025-11-23 08:57:30'),(8,'ODR3919723','0','2025-11-23 11:52:15'),(9,'ODR8739823','0','2025-11-23 12:00:26'),(10,'ODR5702849','0','2025-11-23 12:01:12'),(11,'ODR2356208','0','2025-11-23 12:11:23'),(12,'ODR3232437','0','2025-11-23 12:21:37'),(13,'ODR4715425','0','2025-11-23 12:33:23'),(14,'ODR1574946','0','2025-11-23 12:55:38'),(15,'ODR6329506','0','2025-11-23 12:58:11'),(16,'ODR1731624','0','2025-11-23 13:19:59'),(17,'ODR1669928','0','2025-11-23 13:21:53'),(18,'ODR1497733','0','2025-11-23 13:23:06'),(19,'ODR4245326','To Weigh','2025-11-24 10:36:06'),(20,'ODR6655691','To Weigh','2025-11-24 10:37:21'),(21,'ODR3038915','Pending','2025-11-24 10:38:01'),(22,'ODR6673938','Pending','2025-11-24 10:39:30'),(23,'ODR6673938','To Weigh','2025-11-24 18:02:55'),(24,'ODR1574946','To Weigh','2025-11-24 18:06:14'),(25,'ODR5687837','To Weigh','2025-11-24 21:06:31'),(27,'ODR6306890','Pending','2025-11-24 22:23:55'),(28,'ODR3707820','Pending','2025-11-24 22:27:11'),(29,'ODR1839335','To Weigh','2025-11-24 22:28:05'),(30,'ODR7852487','To Weigh','2025-11-24 22:28:50'),(31,'ODR7394733','Pending','2025-11-24 23:05:51'),(32,'ODR6673938','Processing','2025-11-24 23:23:30'),(33,'ODR6673938','Completed','2025-11-24 23:27:28');
/*!40000 ALTER TABLE `order_status` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `orders`
--

DROP TABLE IF EXISTS `orders`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `orders` (
  `OrderID` varchar(10) NOT NULL,
  `CustID` varchar(10) DEFAULT NULL,
  `StaffID` varchar(10) DEFAULT NULL,
  `ShopID` int(11) NOT NULL,
  `OrderCreatedAt` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`OrderID`),
  KEY `fk_order_customer` (`CustID`),
  KEY `fk_order_staff` (`StaffID`),
  KEY `fk_order_shop` (`ShopID`),
  CONSTRAINT `fk_order_customer` FOREIGN KEY (`CustID`) REFERENCES `customers` (`CustID`) ON DELETE CASCADE,
  CONSTRAINT `fk_order_shop` FOREIGN KEY (`ShopID`) REFERENCES `laundry_shops` (`ShopID`) ON DELETE CASCADE,
  CONSTRAINT `fk_order_staff` FOREIGN KEY (`StaffID`) REFERENCES `staffs` (`StaffID`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `orders`
--

LOCK TABLES `orders` WRITE;
/*!40000 ALTER TABLE `orders` DISABLE KEYS */;
INSERT INTO `orders` VALUES ('ODR1497733','C1','S1',1,'2025-11-23 13:23:06'),('ODR1574946','C1','S1',1,'2025-11-23 12:55:38'),('ODR1669928','C1','S1',1,'2025-11-23 13:21:52'),('ODR1731624','C1','S1',1,'2025-11-23 13:19:59'),('ODR1839335','C1','S1',1,'2025-11-24 22:28:05'),('ODR2356208','C1','S1',1,'2025-11-23 12:11:23'),('ODR3038915','C1','S1',1,'2025-11-24 10:38:01'),('ODR3232437','C1','S1',1,'2025-11-23 12:21:37'),('ODR3707820','C1','S1',1,'2025-11-24 22:27:11'),('ODR3722550','C1','S1',1,'2025-11-23 08:43:13'),('ODR3919723','C1','S1',1,'2025-11-23 11:52:15'),('ODR4183791','C1','S1',1,'2025-11-23 08:00:07'),('ODR4245326','C1','S1',1,'2025-11-24 10:36:06'),('ODR4715425','C1','S1',1,'2025-11-23 12:33:23'),('ODR5247421','C1','S1',1,'2025-11-24 10:10:37'),('ODR5385839','C1','S1',1,'2025-11-23 08:57:30'),('ODR5687837','C1','S1',1,'2025-11-24 21:06:31'),('ODR5702849','C1','S1',1,'2025-11-23 12:01:12'),('ODR6306890','C1','S1',1,'2025-11-24 22:23:55'),('ODR6329506','C1','S1',1,'2025-11-23 12:58:11'),('ODR6655691','C1','S1',1,'2025-11-24 10:37:21'),('ODR6673938','C1','S1',1,'2025-11-24 10:39:30'),('ODR6898980','C1','S1',1,'2025-11-23 08:40:02'),('ODR7394733','C1','S1',1,'2025-11-24 23:05:51'),('ODR7852487','C1','S1',1,'2025-11-24 22:28:50'),('ODR8739823','C1','S1',1,'2025-11-23 12:00:26');
/*!40000 ALTER TABLE `orders` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `otps`
--

DROP TABLE IF EXISTS `otps`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `otps` (
  `otp_id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` varchar(10) NOT NULL,
  `otp_code` varchar(6) NOT NULL,
  `expires_at` datetime NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`otp_id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `otps_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`UserID`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=30 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `otps`
--

LOCK TABLES `otps` WRITE;
/*!40000 ALTER TABLE `otps` DISABLE KEYS */;
/*!40000 ALTER TABLE `otps` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `payment_methods`
--

DROP TABLE IF EXISTS `payment_methods`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `payment_methods` (
  `MethodID` int(11) NOT NULL AUTO_INCREMENT,
  `MethodName` varchar(30) NOT NULL,
  PRIMARY KEY (`MethodID`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `payment_methods`
--

LOCK TABLES `payment_methods` WRITE;
/*!40000 ALTER TABLE `payment_methods` DISABLE KEYS */;
INSERT INTO `payment_methods` VALUES (1,'Cash'),(2,'Paypal');
/*!40000 ALTER TABLE `payment_methods` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `rejected_orders`
--

DROP TABLE IF EXISTS `rejected_orders`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `rejected_orders` (
  `RejectedID` int(11) NOT NULL AUTO_INCREMENT,
  `OrderID` varchar(10) NOT NULL,
  `RejectionReason` varchar(255) NOT NULL,
  `RejectionNote` text DEFAULT NULL,
  `RejectedAt` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`RejectedID`),
  KEY `fk_rejectedorder_order` (`OrderID`),
  CONSTRAINT `fk_rejectedorder_order` FOREIGN KEY (`OrderID`) REFERENCES `orders` (`OrderID`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `rejected_orders`
--

LOCK TABLES `rejected_orders` WRITE;
/*!40000 ALTER TABLE `rejected_orders` DISABLE KEYS */;
/*!40000 ALTER TABLE `rejected_orders` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `services`
--

DROP TABLE IF EXISTS `services`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `services` (
  `SvcID` int(11) NOT NULL AUTO_INCREMENT,
  `SvcName` varchar(50) NOT NULL,
  PRIMARY KEY (`SvcID`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `services`
--

LOCK TABLES `services` WRITE;
/*!40000 ALTER TABLE `services` DISABLE KEYS */;
INSERT INTO `services` VALUES (1,'Wash & Dry'),(2,'Wash, Dry, & Press'),(3,'Press only'),(4,'Wash, Dry, & Fold'),(5,'Full Service');
/*!40000 ALTER TABLE `services` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `shop_add_ons`
--

DROP TABLE IF EXISTS `shop_add_ons`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `shop_add_ons` (
  `ShopID` int(11) NOT NULL,
  `AddOnID` int(11) NOT NULL,
  `AddOnPrice` decimal(10,2) NOT NULL,
  PRIMARY KEY (`ShopID`,`AddOnID`),
  KEY `fk_shopaddon_addon` (`AddOnID`),
  CONSTRAINT `fk_shopaddon_addon` FOREIGN KEY (`AddOnID`) REFERENCES `add_ons` (`AddOnID`) ON DELETE CASCADE,
  CONSTRAINT `fk_shopaddon_shop` FOREIGN KEY (`ShopID`) REFERENCES `laundry_shops` (`ShopID`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `shop_add_ons`
--

LOCK TABLES `shop_add_ons` WRITE;
/*!40000 ALTER TABLE `shop_add_ons` DISABLE KEYS */;
INSERT INTO `shop_add_ons` VALUES (1,1,20.00),(1,2,25.00),(1,3,27.00),(1,5,50.00);
/*!40000 ALTER TABLE `shop_add_ons` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `shop_delivery_app`
--

DROP TABLE IF EXISTS `shop_delivery_app`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `shop_delivery_app` (
  `ShopID` int(11) NOT NULL,
  `DlvryAppID` int(11) NOT NULL,
  PRIMARY KEY (`ShopID`,`DlvryAppID`),
  KEY `fk_sda_app` (`DlvryAppID`),
  CONSTRAINT `fk_sda_app` FOREIGN KEY (`DlvryAppID`) REFERENCES `delivery_app` (`DlvryAppID`) ON DELETE CASCADE,
  CONSTRAINT `fk_sda_shop` FOREIGN KEY (`ShopID`) REFERENCES `laundry_shops` (`ShopID`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `shop_delivery_app`
--

LOCK TABLES `shop_delivery_app` WRITE;
/*!40000 ALTER TABLE `shop_delivery_app` DISABLE KEYS */;
INSERT INTO `shop_delivery_app` VALUES (1,1);
/*!40000 ALTER TABLE `shop_delivery_app` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `shop_delivery_options`
--

DROP TABLE IF EXISTS `shop_delivery_options`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `shop_delivery_options` (
  `DlvryID` int(11) NOT NULL AUTO_INCREMENT,
  `ShopID` int(11) NOT NULL,
  `DlvryTypeID` int(11) NOT NULL,
  PRIMARY KEY (`DlvryID`),
  KEY `fk_shopdelivery_shop` (`ShopID`),
  KEY `fk_shopdelivery_type` (`DlvryTypeID`),
  CONSTRAINT `fk_shopdelivery_shop` FOREIGN KEY (`ShopID`) REFERENCES `laundry_shops` (`ShopID`) ON DELETE CASCADE,
  CONSTRAINT `fk_shopdelivery_type` FOREIGN KEY (`DlvryTypeID`) REFERENCES `delivery_types` (`DlvryTypeID`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `shop_delivery_options`
--

LOCK TABLES `shop_delivery_options` WRITE;
/*!40000 ALTER TABLE `shop_delivery_options` DISABLE KEYS */;
INSERT INTO `shop_delivery_options` VALUES (1,1,1),(2,1,2),(3,1,3),(4,1,4);
/*!40000 ALTER TABLE `shop_delivery_options` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `shop_distance`
--

DROP TABLE IF EXISTS `shop_distance`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `shop_distance` (
  `ShopID` int(11) NOT NULL,
  `ShopLatitude` decimal(10,8) NOT NULL,
  `ShopLongitude` decimal(11,8) NOT NULL,
  KEY `fk_shop_distance` (`ShopID`),
  CONSTRAINT `fk_shop_distance` FOREIGN KEY (`ShopID`) REFERENCES `laundry_shops` (`ShopID`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `shop_distance`
--

LOCK TABLES `shop_distance` WRITE;
/*!40000 ALTER TABLE `shop_distance` DISABLE KEYS */;
INSERT INTO `shop_distance` VALUES (1,10.33083300,123.90638900);
/*!40000 ALTER TABLE `shop_distance` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `shop_fabrics`
--

DROP TABLE IF EXISTS `shop_fabrics`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `shop_fabrics` (
  `ShopID` int(11) NOT NULL,
  `FabID` int(11) NOT NULL,
  PRIMARY KEY (`ShopID`,`FabID`),
  KEY `fk_shopfabric_fabric` (`FabID`),
  CONSTRAINT `fk_shopfabric_fabric` FOREIGN KEY (`FabID`) REFERENCES `fabrics` (`FabID`) ON DELETE CASCADE,
  CONSTRAINT `fk_shopfabric_shop` FOREIGN KEY (`ShopID`) REFERENCES `laundry_shops` (`ShopID`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `shop_fabrics`
--

LOCK TABLES `shop_fabrics` WRITE;
/*!40000 ALTER TABLE `shop_fabrics` DISABLE KEYS */;
INSERT INTO `shop_fabrics` VALUES (1,1),(1,2),(1,3);
/*!40000 ALTER TABLE `shop_fabrics` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `shop_own_service`
--

DROP TABLE IF EXISTS `shop_own_service`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `shop_own_service` (
  `DlvryOwnServiceID` int(11) NOT NULL AUTO_INCREMENT,
  `ShopID` int(11) NOT NULL,
  `ShopBaseFare` decimal(10,2) NOT NULL,
  `ShopBaseKm` int(11) NOT NULL,
  `ShopDistanceRate` decimal(10,2) NOT NULL,
  `ShopServiceStatus` varchar(20) DEFAULT 'Inactive',
  PRIMARY KEY (`DlvryOwnServiceID`),
  UNIQUE KEY `ShopID` (`ShopID`),
  CONSTRAINT `fk_shop_own_service` FOREIGN KEY (`ShopID`) REFERENCES `laundry_shops` (`ShopID`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=19 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `shop_own_service`
--

LOCK TABLES `shop_own_service` WRITE;
/*!40000 ALTER TABLE `shop_own_service` DISABLE KEYS */;
INSERT INTO `shop_own_service` VALUES (1,1,30.00,3,5.00,'Inactive');
/*!40000 ALTER TABLE `shop_own_service` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `shop_owners`
--

DROP TABLE IF EXISTS `shop_owners`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `shop_owners` (
  `OwnerID` varchar(10) NOT NULL,
  `OwnerName` varchar(100) NOT NULL,
  `OwnerPhone` varchar(15) DEFAULT NULL,
  `OwnerAddress` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`OwnerID`),
  CONSTRAINT `fk_shopowner_user` FOREIGN KEY (`OwnerID`) REFERENCES `users` (`UserID`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `shop_owners`
--

LOCK TABLES `shop_owners` WRITE;
/*!40000 ALTER TABLE `shop_owners` DISABLE KEYS */;
INSERT INTO `shop_owners` VALUES ('O1','Test User','09324254244','Test User Address'),('O2','Mock User','09324254244','Mock User Address');
/*!40000 ALTER TABLE `shop_owners` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `shop_rate_stats`
--

DROP TABLE IF EXISTS `shop_rate_stats`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `shop_rate_stats` (
  `ShopStatID` int(11) NOT NULL AUTO_INCREMENT,
  `ShopRevID` int(11) NOT NULL,
  `InitialRating` decimal(2,1) NOT NULL,
  `UpdatedAt` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`ShopStatID`),
  KEY `fk_shopratestats_shoprates` (`ShopRevID`),
  CONSTRAINT `fk_shopratestats_shoprates` FOREIGN KEY (`ShopRevID`) REFERENCES `shop_rates` (`ShopRevID`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `shop_rate_stats`
--

LOCK TABLES `shop_rate_stats` WRITE;
/*!40000 ALTER TABLE `shop_rate_stats` DISABLE KEYS */;
/*!40000 ALTER TABLE `shop_rate_stats` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `shop_rates`
--

DROP TABLE IF EXISTS `shop_rates`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `shop_rates` (
  `ShopRevID` int(11) NOT NULL AUTO_INCREMENT,
  `ShopID` int(11) NOT NULL,
  `ShopRating` decimal(2,1) NOT NULL,
  PRIMARY KEY (`ShopRevID`),
  KEY `fk_shoprates_shop` (`ShopID`),
  CONSTRAINT `fk_shoprates_shop` FOREIGN KEY (`ShopID`) REFERENCES `laundry_shops` (`ShopID`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `shop_rates`
--

LOCK TABLES `shop_rates` WRITE;
/*!40000 ALTER TABLE `shop_rates` DISABLE KEYS */;
/*!40000 ALTER TABLE `shop_rates` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `shop_services`
--

DROP TABLE IF EXISTS `shop_services`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `shop_services` (
  `ShopID` int(11) NOT NULL,
  `SvcID` int(11) NOT NULL,
  `SvcPrice` decimal(10,2) NOT NULL,
  `MinWeight` int(11) DEFAULT NULL,
  PRIMARY KEY (`ShopID`,`SvcID`),
  KEY `fk_shopservice_service` (`SvcID`),
  CONSTRAINT `fk_shopservice_service` FOREIGN KEY (`SvcID`) REFERENCES `services` (`SvcID`) ON DELETE CASCADE,
  CONSTRAINT `fk_shopservice_shop` FOREIGN KEY (`ShopID`) REFERENCES `laundry_shops` (`ShopID`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `shop_services`
--

LOCK TABLES `shop_services` WRITE;
/*!40000 ALTER TABLE `shop_services` DISABLE KEYS */;
INSERT INTO `shop_services` VALUES (1,1,50.00,3),(1,2,55.00,3),(1,3,40.00,1),(1,4,55.00,3),(1,5,60.00,3);
/*!40000 ALTER TABLE `shop_services` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `staff_infos`
--

DROP TABLE IF EXISTS `staff_infos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `staff_infos` (
  `StaffInfoID` int(11) NOT NULL AUTO_INCREMENT,
  `StaffID` varchar(10) NOT NULL,
  `StaffAge` int(11) DEFAULT NULL,
  `StaffAddress` varchar(100) DEFAULT NULL,
  `StaffCellNo` varchar(15) DEFAULT NULL,
  `StaffSalary` decimal(10,2) DEFAULT NULL,
  PRIMARY KEY (`StaffInfoID`),
  KEY `fk_staff_info` (`StaffID`),
  CONSTRAINT `fk_staff_info` FOREIGN KEY (`StaffID`) REFERENCES `staffs` (`StaffID`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `staff_infos`
--

LOCK TABLES `staff_infos` WRITE;
/*!40000 ALTER TABLE `staff_infos` DISABLE KEYS */;
INSERT INTO `staff_infos` VALUES (1,'S1',18,'Taga Inyoha','09234242353',45000.00),(2,'S2',45,'Wa Hibaw','09314424555',150000.00);
/*!40000 ALTER TABLE `staff_infos` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `staffs`
--

DROP TABLE IF EXISTS `staffs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `staffs` (
  `StaffID` varchar(10) NOT NULL,
  `StaffName` varchar(50) NOT NULL,
  `StaffRole` varchar(20) DEFAULT NULL,
  `ShopID` int(11) NOT NULL,
  PRIMARY KEY (`StaffID`),
  KEY `fk_staff_shop` (`ShopID`),
  CONSTRAINT `fk_staff_shop` FOREIGN KEY (`ShopID`) REFERENCES `laundry_shops` (`ShopID`) ON DELETE CASCADE,
  CONSTRAINT `fk_staff_user` FOREIGN KEY (`StaffID`) REFERENCES `users` (`UserID`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `staffs`
--

LOCK TABLES `staffs` WRITE;
/*!40000 ALTER TABLE `staffs` DISABLE KEYS */;
INSERT INTO `staffs` VALUES ('S1','Barako Lamaw','Cashier',1),('S2','Wa El','Staff',1);
/*!40000 ALTER TABLE `staffs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `systemconfig`
--

DROP TABLE IF EXISTS `systemconfig`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `systemconfig` (
  `ConfigKey` varchar(50) NOT NULL,
  `ConfigValue` varchar(255) NOT NULL,
  PRIMARY KEY (`ConfigKey`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `systemconfig`
--

LOCK TABLES `systemconfig` WRITE;
/*!40000 ALTER TABLE `systemconfig` DISABLE KEYS */;
INSERT INTO `systemconfig` VALUES ('MAINTENANCE_MODE','false');
/*!40000 ALTER TABLE `systemconfig` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user_logs`
--

DROP TABLE IF EXISTS `user_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_logs` (
  `UserLogID` int(11) NOT NULL AUTO_INCREMENT,
  `UserID` varchar(10) NOT NULL,
  `UserRole` varchar(50) DEFAULT NULL,
  `UsrLogAction` varchar(100) NOT NULL,
  `UsrLogDescrpt` varchar(255) DEFAULT NULL,
  `UsrLogTmstp` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`UserLogID`),
  KEY `fk_userlogs_user` (`UserID`),
  CONSTRAINT `fk_userlogs_user` FOREIGN KEY (`UserID`) REFERENCES `users` (`UserID`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=124 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_logs`
--

LOCK TABLES `user_logs` WRITE;
/*!40000 ALTER TABLE `user_logs` DISABLE KEYS */;
INSERT INTO `user_logs` VALUES (1,'A1','Admin','Login','Direct login success','2025-11-22 16:32:12'),(2,'O1','Shop Owner','Shop Owner Creation','New Shop Owner account created: O1','2025-11-22 16:32:48'),(3,'O1','Shop Owner','Login','Direct login success','2025-11-22 16:32:59'),(4,'S1','Staff','Staff Creation','New staff: Barako Lamaw (barako1)','2025-11-22 16:58:52'),(5,'S2','Staff','Staff Creation','New staff: Wa El (wa1)','2025-11-22 16:59:55'),(6,'A1','Admin','Login','Direct login success','2025-11-22 17:09:21'),(7,'A1','Admin','Data Security','Generated system backup: laundrolink_db_2025-11-22T17-19-23-570Z.sql','2025-11-22 17:19:30'),(8,'A1','Admin','Data Security','Downloaded backup file: laundrolink_db_2025-11-22T17-19-23-570Z.sql','2025-11-22 17:19:31'),(9,'A1','Admin','System Config','Maintenance mode set to: true','2025-11-22 17:22:46'),(10,'A1','Admin','System Config','Maintenance mode set to: false','2025-11-22 17:22:54'),(11,'O1','Shop Owner','Login','Direct login success','2025-11-22 17:23:35'),(12,'C1','Customer','Sign-up','User created via Google','2025-11-22 18:18:22'),(17,'C1','Customer','Login Failed','Invalid password','2025-11-22 18:25:55'),(18,'C1','Customer','Login','OTP Verified Success','2025-11-22 18:26:20'),(19,'C1','Customer','Login','OTP Verified Success','2025-11-22 19:21:06'),(20,'C1','Customer','Login','OTP Verified Success','2025-11-22 20:05:50'),(21,'C1','Customer','Login','OTP Verified Success','2025-11-22 20:38:14'),(22,'C1','Customer','Login','OTP Verified Success','2025-11-22 22:01:21'),(23,'C1','Customer','Login','OTP Verified Success','2025-11-22 22:05:38'),(24,'C1','Customer','Login','OTP Verified Success','2025-11-22 22:27:38'),(25,'C1','Customer','Login','OTP Verified Success','2025-11-22 22:30:25'),(26,'O1','Shop Owner','Login','Direct login success','2025-11-22 22:55:07'),(27,'O1','Shop Owner','Login','Direct login success','2025-11-22 22:55:28'),(28,'C1','Customer','Login','OTP Verified Success','2025-11-23 07:23:19'),(29,'C1','Customer','Login','OTP Verified Success','2025-11-23 07:55:33'),(30,'C1','Customer','Create Order','New order created: ODR4183791','2025-11-23 08:00:07'),(31,'C1','Customer','Create Order','New order created: ODR6898980','2025-11-23 08:40:02'),(32,'C1','Customer','Create Order','New order created: ODR3722550','2025-11-23 08:43:13'),(33,'C1','Customer','Login','OTP Verified Success','2025-11-23 08:57:12'),(34,'C1','Customer','Create Order','New order created: ODR5385839','2025-11-23 08:57:30'),(35,'O1','Shop Owner','Login','Direct login success','2025-11-23 10:03:09'),(36,'O1','Shop Owner','Login','Direct login success','2025-11-23 10:03:29'),(37,'C1','Customer','Login','OTP Verified Success','2025-11-23 10:04:11'),(38,'C1','Customer','Login','OTP Verified Success','2025-11-23 11:18:37'),(39,'C1','Customer','Login','OTP Verified Success','2025-11-23 11:36:16'),(40,'C1','Customer','Create Order','New order created: ODR3919723','2025-11-23 11:52:15'),(41,'C1','Customer','Create Order','New order created: ODR8739823','2025-11-23 12:00:26'),(42,'C1','Customer','Create Order','New order created: ODR5702849','2025-11-23 12:01:12'),(43,'C1','Customer','Login','OTP Verified Success','2025-11-23 12:10:07'),(44,'C1','Customer','Create Order','New order created: ODR2356208','2025-11-23 12:11:23'),(45,'C1','Customer','Login','OTP Verified Success','2025-11-23 12:17:13'),(46,'C1','Customer','Create Order','New order created: ODR3232437','2025-11-23 12:21:37'),(47,'C1','Customer','Login','OTP Verified Success','2025-11-23 12:32:12'),(48,'C1','Customer','Create Order','New order created: ODR4715425','2025-11-23 12:33:23'),(49,'C1','Customer','Login','OTP Verified Success','2025-11-23 12:47:23'),(50,'C1','Customer','Create Order','New order created: ODR1574946','2025-11-23 12:55:38'),(51,'C1','Customer','Create Order','New order created: ODR6329506','2025-11-23 12:58:11'),(52,'C1','Customer','Create Order','New order created: ODR1731624','2025-11-23 13:19:59'),(53,'C1','Customer','Create Order','New order created: ODR1669928','2025-11-23 13:21:53'),(54,'C1','Customer','Create Order','New order created: ODR1497733','2025-11-23 13:23:06'),(55,'S1','Staff','Login','Direct login success','2025-11-23 15:07:06'),(56,'C1','Customer','Login','OTP Verified Success','2025-11-23 16:06:49'),(57,'C1','Customer','Login','OTP Verified Success','2025-11-24 10:09:42'),(58,'C1','Customer','Create Order','New order created: ODR5247421','2025-11-24 10:10:37'),(59,'C1','Customer','Login','OTP Verified Success','2025-11-24 10:26:48'),(60,'C1','Customer','Login','OTP Verified Success','2025-11-24 10:35:39'),(61,'C1','Customer','Create Order','New order created: ODR4245326','2025-11-24 10:36:06'),(62,'C1','Customer','Create Order','New order created: ODR6655691','2025-11-24 10:37:21'),(63,'C1','Customer','Create Order','New order created: ODR3038915','2025-11-24 10:38:01'),(64,'C1','Customer','Create Order','New order created: ODR6673938','2025-11-24 10:39:30'),(67,'S1','Staff','Login Failed','Invalid password','2025-11-24 10:48:19'),(68,'S1','Staff','Login','Direct login success','2025-11-24 10:48:22'),(69,'S1','Staff','Login','Direct login success','2025-11-24 11:19:37'),(70,'S1','Staff','Login','Direct login success','2025-11-24 11:22:35'),(71,'S1','Staff','Login','Direct login success','2025-11-24 11:25:34'),(72,'S1','Staff','Login','Direct login success','2025-11-24 11:30:55'),(73,'S1','Staff','Login','Direct login success','2025-11-24 11:34:40'),(74,'S1','Staff','Login','Direct login success','2025-11-24 11:46:37'),(75,'S1','Staff','Login','Direct login success','2025-11-24 11:55:44'),(76,'S1','Staff','Login','Direct login success','2025-11-24 11:57:25'),(77,'S1','Staff','Login','Direct login success','2025-11-24 11:59:14'),(78,'S1','Staff','Login','Direct login success','2025-11-24 12:00:25'),(79,'S1','Staff','Login','Direct login success','2025-11-24 13:43:49'),(80,'S1','Staff','Login','Direct login success','2025-11-24 14:07:58'),(81,'S1','Staff','Login','Direct login success','2025-11-24 14:16:54'),(82,'S1','Staff','Login','Direct login success','2025-11-24 14:22:18'),(83,'S1','Staff','Login','Direct login success','2025-11-24 14:26:47'),(84,'S1','Staff','Login','Direct login success','2025-11-24 14:27:47'),(85,'S1','Staff','Login','Direct login success','2025-11-24 15:13:58'),(86,'S1','Staff','Login','Direct login success','2025-11-24 16:10:28'),(87,'S1','Staff','Login','Direct login success','2025-11-24 16:11:48'),(88,'S1','Cashier','Confirm Delivery Pay','Delivery payment confirmed for Order ODR6673938','2025-11-24 16:23:47'),(89,'S1','Cashier','Confirm Delivery Pay','Delivery payment confirmed for Order ODR1574946','2025-11-24 16:31:45'),(90,'S1','Staff','Login','Direct login success','2025-11-24 17:25:01'),(91,'O1','Shop Owner','Login','Direct login success','2025-11-24 17:31:28'),(92,'S1','Staff','Update Delivery Status','Order ODR6673938: Arrived at Customer, To Weigh','2025-11-24 18:02:55'),(93,'S1','Staff','Delivery Booking','Proof uploaded for Order ODR1574946','2025-11-24 18:04:24'),(94,'S1','Staff','Update Delivery Status','Order ODR1574946: Delivered In Shop, To Weigh','2025-11-24 18:06:14'),(95,'S1','Staff','Login','Direct login success','2025-11-24 20:33:36'),(96,'S1','Staff','Update Weight','Order ODR6673938 weight updated to 5.5kg with proof.','2025-11-24 20:34:36'),(97,'S1','Staff','Update Weight','Order ODR6673938 weight updated to 7.5kg with proof.','2025-11-24 20:55:14'),(98,'C1','Customer','Login','OTP Verified Success','2025-11-24 21:05:19'),(99,'C1','Customer','Create Order','New order created: ODR5687837','2025-11-24 21:06:31'),(100,'S1','Staff','Update Weight','Order ODR5687837 weight updated to 5kg with proof.','2025-11-24 21:08:04'),(101,'S1','Staff','Update Weight','Order ODR6655691 weight updated to 6.5kg with proof.','2025-11-24 21:10:58'),(102,'C1','Customer','Create Order','New order created: ODR6306890','2025-11-24 22:23:55'),(103,'C1','Customer','Create Order','New order created: ODR3707820','2025-11-24 22:27:11'),(104,'C1','Customer','Create Order','New order created: ODR1839335','2025-11-24 22:28:05'),(105,'C1','Customer','Create Order','New order created: ODR7852487','2025-11-24 22:28:50'),(106,'C1','Customer','Login','OTP Verified Success','2025-11-24 22:39:16'),(107,'C1','Customer','Login Failed','Invalid password','2025-11-24 22:43:25'),(108,'C1','Customer','Login','OTP Verified Success','2025-11-24 22:43:48'),(109,'C1','Customer','Create Order','New order created: ODR7394733','2025-11-24 23:05:51'),(110,'S1','Staff','Login','Direct login success','2025-11-24 23:19:04'),(111,'S1','Cashier','Confirm Delivery Pay','Delivery payment confirmed for Order ODR6329506','2025-11-24 23:22:04'),(112,'S1','Cashier','Confirm Delivery Pay','Delivery payment confirmed for Order ODR7394733','2025-11-24 23:22:14'),(113,'S1','Cashier','Confirm Delivery Pay','Delivery payment confirmed for Order ODR3707820','2025-11-24 23:22:46'),(114,'S1','Cashier','Confirm Delivery Pay','Delivery payment confirmed for Order ODR3038915','2025-11-24 23:22:52'),(115,'S1','Cashier','Confirm Payment','Service payment confirmed for Order ODR6673938','2025-11-24 23:23:30'),(116,'S1','Staff','Update Order Status','Order ODR6673938 status: Out for Delivery','2025-11-24 23:27:28'),(117,'C1','Customer','Profile Update','Customer updated profile','2025-11-24 23:38:19'),(118,'C1','Customer','Login','OTP Verified Success','2025-11-24 23:39:27'),(119,'C1','Customer','Login','OTP Verified Success','2025-11-25 00:01:08'),(120,'C1','Customer','Login','OTP Verified Success','2025-11-25 00:22:16'),(121,'A1','Admin','Login','Direct login success','2025-11-25 07:06:08'),(122,'O2','Shop Owner','Shop Owner Creation','New Shop Owner account created: O2','2025-11-25 07:08:48'),(123,'O2','Shop Owner','User Status Change','Shop Owner O2 Deactivated','2025-11-25 07:09:37');
/*!40000 ALTER TABLE `user_logs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `UserID` varchar(10) NOT NULL,
  `UserEmail` varchar(100) NOT NULL,
  `UserPassword` varchar(100) DEFAULT NULL,
  `UserRole` varchar(20) NOT NULL,
  `DateCreated` timestamp NOT NULL DEFAULT current_timestamp(),
  `IsActive` tinyint(1) DEFAULT 1,
  PRIMARY KEY (`UserID`),
  UNIQUE KEY `UserEmail` (`UserEmail`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES ('A1','mj1','mj1','Admin','2025-09-15 02:00:01',1),('A2','juriel2','juriel2','Admin','2025-09-15 02:00:02',1),('A3','kezhea3','kezhea3','Admin','2025-09-15 02:00:03',1),('A4','jasper4','jasper4','Admin','2025-09-15 02:00:04',1),('C1','jhongulane125@gmail.com','jhon123','Customer','2025-11-22 18:18:22',1),('O1','testuser@gmail.com','$2b$10$CPNAwd8k9yhSJEqBpLl4r.KravvkKv/rFwKfUUrWJHBK2COfPENfi','Shop Owner','2025-11-22 16:32:48',1),('O2','mockuser@gmail.com','$2b$10$xpx5aCl1etnRaMaaPe4ti.xCIU3Dl4Dwxsh5oWDoUN.q.6PIhPx9m','Shop Owner','2025-11-25 07:08:48',0),('S1','barako1','$2b$10$z7e9iLl4ih2ufsP6e03HtO9/haiIPrML3BhP48uotcGrggM/rQHKq','Staff','2025-11-22 16:58:52',1),('S2','wa1','$2b$10$aFAwAMa9ayeXxNyXO//K0.P5Fbdx4183jq08pQ7xxoS3SurOZ4zEe','Staff','2025-11-22 16:59:55',1);
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2025-11-25 15:12:41
