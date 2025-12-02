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
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `conversations`
--

LOCK TABLES `conversations` WRITE;
/*!40000 ALTER TABLE `conversations` DISABLE KEYS */;
INSERT INTO `conversations` VALUES (1,'C1','S1','2025-11-29 13:24:36'),(2,'C2','S3','2025-11-29 13:41:45'),(3,'C1','S2','2025-11-29 14:09:15'),(4,'C2','S2','2025-11-29 14:24:09'),(5,'C1','S3','2025-11-29 14:24:13'),(6,'C2','S1','2025-11-29 14:47:08');
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
INSERT INTO `cust_credentials` VALUES ('C1','116938147026298023540',1,'https://lh3.googleusercontent.com/a/ACg8ocKpwp_W4OG8Q9gMKLLx6YQfUEbsoXBZbaETLM_at9whInM1Tg=s96-c','google',NULL,NULL),('C2','108123800582683307374',1,'https://lh3.googleusercontent.com/a/ACg8ocJLJTIVjROxOhIxgNyKSbwkatkeUwNxxm3w4qb305q9twZYntfW=s96-c','google',NULL,NULL),('C3','106921559400181425394',1,'https://lh3.googleusercontent.com/a/ACg8ocLaZlbJzDJK3g1yvw6nR1O_oL9LNgrx2yyyFeEeasxZUt78cKEl=s96-c','google',NULL,NULL);
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
  UNIQUE KEY `OrderID` (`OrderID`),
  CONSTRAINT `fk_customerrating_order` FOREIGN KEY (`OrderID`) REFERENCES `orders` (`OrderID`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `customer_ratings`
--

LOCK TABLES `customer_ratings` WRITE;
/*!40000 ALTER TABLE `customer_ratings` DISABLE KEYS */;
INSERT INTO `customer_ratings` VALUES (1,'ODR1451434',5.0,'Testing Phase 1 Excellent'),(2,'ODR5613842',5.0,'TESTING PHASE 2 EXCELLENT'),(3,'ODR9176155',5.0,'TESTING PHASE 3 EXCELLENT'),(4,'ODR9020178',5.0,'TESTING PHASE 3 EXCELLENT'),(5,'ODR1697311',5.0,'Sheeeezzzz'),(6,'ODR6695789',5.0,'sheeezeee'),(7,'ODR3832545',4.0,'FINAL PHASE MARVELOUS'),(8,'ODR8648113',3.0,'FINAL PHASE MARVELOUS THANKS G');
/*!40000 ALTER TABLE `customer_ratings` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `customer_segments`
--

DROP TABLE IF EXISTS `customer_segments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `customer_segments` (
  `SegID` int(11) NOT NULL AUTO_INCREMENT,
  `ShopID` int(11) NOT NULL,
  `CustID` varchar(10) NOT NULL,
  `SegmentName` varchar(50) DEFAULT NULL,
  `TotalSpend` decimal(10,2) DEFAULT NULL,
  `Frequency` int(11) DEFAULT NULL,
  `Recency` int(11) DEFAULT NULL,
  `LastUpdated` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`SegID`),
  KEY `fk_seg_shop` (`ShopID`),
  KEY `fk_seg_cust` (`CustID`),
  CONSTRAINT `fk_seg_cust` FOREIGN KEY (`CustID`) REFERENCES `customers` (`CustID`) ON DELETE CASCADE,
  CONSTRAINT `fk_seg_shop` FOREIGN KEY (`ShopID`) REFERENCES `laundry_shops` (`ShopID`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `customer_segments`
--

LOCK TABLES `customer_segments` WRITE;
/*!40000 ALTER TABLE `customer_segments` DISABLE KEYS */;
/*!40000 ALTER TABLE `customer_segments` ENABLE KEYS */;
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
INSERT INTO `customers` VALUES ('C1','JURIEL','09124345393','La Aldea Buena Mactan, Basak, Lapu-Lapu, Central Visayas, 6015, Philippines'),('C2','ULTRA MEGA','09135131951','La Aldea Buena Mactan, Basak, Lapu-Lapu, Central Visayas, 6015, Philippines'),('C3','C/Pvt Gulane',NULL,NULL);
/*!40000 ALTER TABLE `customers` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `deactivated_account`
--

DROP TABLE IF EXISTS `deactivated_account`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `deactivated_account` (
  `UserID` varchar(10) NOT NULL,
  `Reason` text DEFAULT NULL,
  `StatusUpdatedAt` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`UserID`),
  CONSTRAINT `fk_deactivated_user` FOREIGN KEY (`UserID`) REFERENCES `users` (`UserID`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `deactivated_account`
--

LOCK TABLES `deactivated_account` WRITE;
/*!40000 ALTER TABLE `deactivated_account` DISABLE KEYS */;
INSERT INTO `deactivated_account` VALUES ('O4','Violation','2025-12-02 02:19:35');
/*!40000 ALTER TABLE `deactivated_account` ENABLE KEYS */;
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
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `delivery_booking_proofs`
--

LOCK TABLES `delivery_booking_proofs` WRITE;
/*!40000 ALTER TABLE `delivery_booking_proofs` DISABLE KEYS */;
INSERT INTO `delivery_booking_proofs` VALUES (1,'ODR1451434','https://res.cloudinary.com/dihmaok1f/image/upload/v1764422608/laundrolink_delivery_proofs/irlm9we5f4i7klfb8hg2.jpg','2025-11-29 13:23:30'),(2,'ODR1451434','https://res.cloudinary.com/dihmaok1f/image/upload/v1764422950/laundrolink_delivery_proofs/t1cgdi4s8w2srvqha44l.jpg','2025-11-29 13:29:12'),(3,'ODR9176155','https://res.cloudinary.com/dihmaok1f/image/upload/v1764425726/laundrolink_delivery_proofs/dcjhsl3jdcl7beuxc5yb.jpg','2025-11-29 14:15:28'),(4,'ODR1697311','https://res.cloudinary.com/dihmaok1f/image/upload/v1764426174/laundrolink_delivery_proofs/z8og9dmdrd6dweazoeat.jpg','2025-11-29 14:22:55');
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
  UNIQUE KEY `OrderID` (`OrderID`),
  KEY `fk_delivery_payment` (`MethodID`),
  CONSTRAINT `fk_delivery_payment` FOREIGN KEY (`MethodID`) REFERENCES `payment_methods` (`MethodID`) ON DELETE CASCADE,
  CONSTRAINT `fk_dlvry_pay_order` FOREIGN KEY (`OrderID`) REFERENCES `orders` (`OrderID`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `delivery_payments`
--

LOCK TABLES `delivery_payments` WRITE;
/*!40000 ALTER TABLE `delivery_payments` DISABLE KEYS */;
INSERT INTO `delivery_payments` VALUES (1,'ODR1451434',154.00,2,'https://res.cloudinary.com/dihmaok1f/image/upload/v1764422445/laundrolink_payment_proofs/wdvuawkedp2c1dvcgjwo.jpg','Paid','2025-11-29 13:22:47','2025-11-29 13:16:58'),(2,'ODR5613842',40.00,2,'https://res.cloudinary.com/dihmaok1f/image/upload/v1764423510/laundrolink_payment_proofs/rxydseq5tpkedvd8wnal.jpg','Paid','2025-11-29 13:39:54','2025-11-29 13:37:47'),(3,'ODR9176155',77.00,NULL,NULL,'Pending Later','2025-11-29 14:02:31','2025-11-29 14:02:31'),(4,'ODR9020178',20.00,NULL,NULL,'Pending Later','2025-11-29 14:02:38','2025-11-29 14:02:38'),(5,'ODR1697311',77.00,1,NULL,'Paid','2025-11-29 14:21:49','2025-11-29 14:21:04'),(6,'ODR6695789',20.00,1,NULL,'Paid','2025-11-29 14:21:57','2025-11-29 14:21:07'),(7,'ODR9210187',154.00,1,NULL,'Paid','2025-12-01 01:52:36','2025-12-01 01:49:13'),(9,'ODR9435018',77.00,NULL,NULL,'Voided','2025-12-01 02:30:54','2025-12-01 02:30:44');
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
  UNIQUE KEY `uq_dlvry_stat_pair` (`OrderID`,`DlvryStatus`),
  CONSTRAINT `fk_delivery_status_order` FOREIGN KEY (`OrderID`) REFERENCES `orders` (`OrderID`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=22 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `delivery_status`
--

LOCK TABLES `delivery_status` WRITE;
/*!40000 ALTER TABLE `delivery_status` DISABLE KEYS */;
INSERT INTO `delivery_status` VALUES (1,'ODR1451434','To Pick-up','2025-11-29 13:22:47'),(2,'ODR1451434','Rider Booked To Pick-up','2025-11-29 13:23:30'),(3,'ODR1451434','Delivered In Shop','2025-11-29 13:23:55'),(4,'ODR1451434','For Delivery','2025-11-29 13:28:23'),(5,'ODR1451434','Rider Booked For Delivery','2025-11-29 13:29:12'),(6,'ODR1451434','Delivered To Customer','2025-11-29 13:29:34'),(7,'ODR5613842','To Pick-up','2025-11-29 13:39:54'),(8,'ODR5613842','Arrived at Customer','2025-11-29 13:40:46'),(9,'ODR5613842','For Delivery','2025-11-29 13:45:28'),(10,'ODR5613842','Delivered To Customer','2025-11-29 13:45:59'),(11,'ODR9020178','For Delivery','2025-11-29 14:14:26'),(12,'ODR9176155','For Delivery','2025-11-29 14:14:52'),(13,'ODR9020178','Delivered To Customer','2025-11-29 14:15:16'),(14,'ODR9176155','Rider Booked For Delivery','2025-11-29 14:15:28'),(15,'ODR9176155','Delivered To Customer','2025-11-29 14:16:07'),(16,'ODR1697311','To Pick-up','2025-11-29 14:21:49'),(17,'ODR6695789','To Pick-up','2025-11-29 14:21:57'),(18,'ODR1697311','Rider Booked To Pick-up','2025-11-29 14:22:55'),(19,'ODR6695789','Arrived at Customer','2025-11-29 14:22:55'),(20,'ODR1697311','Delivered In Shop','2025-11-29 14:23:25'),(21,'ODR9210187','To Pick-up','2025-12-01 01:52:36');
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
  UNIQUE KEY `OrderID` (`OrderID`),
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
INSERT INTO `invoices` VALUES ('INV1307692','ODR5613842',2,279.00,'https://res.cloudinary.com/dihmaok1f/image/upload/v1764423766/laundrolink_payment_proofs/yryn4wceeqdouhlzez43.jpg','Paid','2025-11-29 13:43:24','2025-11-29 13:41:45'),('INV1695392','ODR6695789',1,287.00,NULL,'Paid','2025-11-29 14:25:10','2025-11-29 14:24:13'),('INV3750157','ODR3638982',2,147.00,'https://res.cloudinary.com/dihmaok1f/image/upload/v1764556816/laundrolink_payment_proofs/gbhz5afxfmr8ygskwrsz.jpg','Paid','2025-12-01 02:40:37','2025-12-01 02:39:24'),('INV4413706','ODR3832545',1,511.00,NULL,'Paid','2025-11-29 14:47:51','2025-11-29 14:47:08'),('INV4932077','ODR8597115',NULL,1392.00,NULL,'Cancelled','2025-12-01 02:37:55','2025-12-01 02:37:47'),('INV5790927','ODR9176155',2,327.00,'https://res.cloudinary.com/dihmaok1f/image/upload/v1764425518/laundrolink_payment_proofs/znptplwwk2faxlnodntb.jpg','Paid','2025-11-29 14:12:41','2025-11-29 14:09:15'),('INV5966834','ODR1451434',2,315.00,'https://res.cloudinary.com/dihmaok1f/image/upload/v1764422825/laundrolink_payment_proofs/os7ngirtyss8xdffjd1r.jpg','Paid','2025-11-29 13:27:24','2025-11-29 13:24:36'),('INV6053527','ODR9020178',2,281.50,'https://res.cloudinary.com/dihmaok1f/image/upload/v1764425508/laundrolink_payment_proofs/siw7sk1hdsro8dwbmi3e.jpg','Paid','2025-11-29 14:12:45','2025-11-29 14:10:47'),('INV6978277','ODR4126856',NULL,184.50,NULL,'Voided','2025-12-01 02:34:19','2025-12-01 02:34:10'),('INV7219193','ODR8648113',1,521.00,NULL,'Paid','2025-11-29 14:47:41','2025-11-29 14:29:44'),('INV8032995','ODR1750725',1,148.50,NULL,'Paid','2025-12-01 02:40:47','2025-12-01 01:53:21'),('INV8652087','ODR1697311',1,265.00,NULL,'Paid','2025-11-29 14:25:15','2025-11-29 14:24:09');
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
  `DlvryTypeID` int(11) NOT NULL,
  `Kilogram` decimal(5,1) DEFAULT 0.0,
  `SpecialInstr` varchar(300) DEFAULT NULL,
  `WeightProofImage` text DEFAULT NULL,
  PRIMARY KEY (`LndryDtlID`),
  UNIQUE KEY `OrderID` (`OrderID`),
  KEY `fk_order_service` (`SvcID`),
  KEY `fk_order_delivery` (`DlvryTypeID`),
  CONSTRAINT `fk_laundrydetails_order` FOREIGN KEY (`OrderID`) REFERENCES `orders` (`OrderID`) ON DELETE CASCADE,
  CONSTRAINT `fk_order_delivery` FOREIGN KEY (`DlvryTypeID`) REFERENCES `delivery_types` (`DlvryTypeID`) ON DELETE CASCADE,
  CONSTRAINT `fk_order_service` FOREIGN KEY (`SvcID`) REFERENCES `services` (`SvcID`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `laundry_details`
--

LOCK TABLES `laundry_details` WRITE;
/*!40000 ALTER TABLE `laundry_details` DISABLE KEYS */;
INSERT INTO `laundry_details` VALUES (1,'ODR1451434',1,4,6.0,'Yrgg','https://res.cloudinary.com/dihmaok1f/image/upload/v1764422675/laundrolink_weight_proofs/idrtdrotvoaxhizikcjb.jpg'),(2,'ODR5613842',2,4,9.0,'hdhd','https://res.cloudinary.com/dihmaok1f/image/upload/v1764423704/laundrolink_weight_proofs/r8yoiekzjljjrbz05rgk.jpg'),(3,'ODR9176155',2,3,9.5,NULL,'https://res.cloudinary.com/dihmaok1f/image/upload/v1764425354/laundrolink_weight_proofs/hqhmnvxpsjfi9qka3pnj.jpg'),(4,'ODR9020178',1,3,10.5,NULL,'https://res.cloudinary.com/dihmaok1f/image/upload/v1764425445/laundrolink_weight_proofs/agmzlvhneytmtuzxp3ry.jpg'),(5,'ODR1697311',3,2,8.2,NULL,'https://res.cloudinary.com/dihmaok1f/image/upload/v1764426248/laundrolink_weight_proofs/bhlbsgqmbe9gicapxtwq.jpg'),(6,'ODR6695789',3,2,8.9,NULL,'https://res.cloudinary.com/dihmaok1f/image/upload/v1764426251/laundrolink_weight_proofs/i4errls5rhhghmiftqgy.jpg'),(7,'ODR8648113',4,1,15.5,NULL,'https://res.cloudinary.com/dihmaok1f/image/upload/v1764426583/laundrolink_weight_proofs/zvvfltbiacccsgezeuya.jpg'),(8,'ODR3832545',4,1,18.0,NULL,'https://res.cloudinary.com/dihmaok1f/image/upload/v1764427627/laundrolink_weight_proofs/qld2ttamsfa1jcoz3smc.jpg'),(9,'ODR1750725',1,1,5.5,NULL,'https://res.cloudinary.com/dihmaok1f/image/upload/v1764554000/laundrolink_weight_proofs/qyfhfcwjljvusvkzbbrz.jpg'),(10,'ODR9210187',3,4,0.0,NULL,NULL),(12,'ODR9435018',2,2,0.0,NULL,NULL),(13,'ODR4126856',3,1,6.5,NULL,'https://res.cloudinary.com/dihmaok1f/image/upload/v1764556449/laundrolink_weight_proofs/fwjoeovexslp6zds09kl.jpg'),(14,'ODR8597115',2,1,58.0,NULL,'https://res.cloudinary.com/dihmaok1f/image/upload/v1764556666/laundrolink_weight_proofs/yait45mrj3hfjoyaqoyl.jpg'),(15,'ODR3638982',3,1,5.0,NULL,'https://res.cloudinary.com/dihmaok1f/image/upload/v1764556764/laundrolink_weight_proofs/zfjwigmj0uhvmzalaoce.jpg');
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
  UNIQUE KEY `OwnerID` (`OwnerID`),
  CONSTRAINT `fk_laundryshop_owner` FOREIGN KEY (`OwnerID`) REFERENCES `shop_owners` (`OwnerID`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `laundry_shops`
--

LOCK TABLES `laundry_shops` WRITE;
/*!40000 ALTER TABLE `laundry_shops` DISABLE KEYS */;
INSERT INTO `laundry_shops` VALUES (1,'O1','Wash N\' Dry','Experience top-notch laundry facilities equipped with state-of-the-art machines and a clean, comfortable environment.','Wilson St., Lahug, Cebu City','09342545344','8:00 am - 9:00 pm','Available','2025-11-29 12:14:54','https://res.cloudinary.com/dihmaok1f/image/upload/v1764418493/laundrolink_shop_images/shop_1764418491820.png'),(2,'O2','Sparklean','Offering comprehensive laundry services with a focus on quality and customer satisfaction.','Apas, Cebu City','09123456789','7:00 am - 6:00 pm','Available','2025-11-29 12:24:52','https://res.cloudinary.com/dihmaok1f/image/upload/v1764419091/laundrolink_shop_images/shop_1764419089481.jpg'),(3,'O3','Test User Laundry Shop','ksghfljalegljjzhjkshglvhsghvsl','La Aldea Buena Mactan, Basak, Lapu-Lapu, Central Visayas, 6015, Philippines','09123456789','8:00 am - 9:00 pm','Available','2025-12-02 00:26:05','https://res.cloudinary.com/dihmaok1f/image/upload/v1764635165/laundrolink_shop_images/shop_1764635162771.jpg'),(4,'O4','Laundry Shop','Clean laundry shop','Wilson St., Lahug, Cebu City','09123456789','8:00 am - 9:00 pm','Available','2025-12-02 02:18:20','https://res.cloudinary.com/dihmaok1f/image/upload/v1764641900/laundrolink_shop_images/shop_1764641898035.jpg');
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
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `messages`
--

LOCK TABLES `messages` WRITE;
/*!40000 ALTER TABLE `messages` DISABLE KEYS */;
INSERT INTO `messages` VALUES (1,1,'S1','C1','Weight has been updated, please proceed to payment.',NULL,'Sent','2025-11-29 13:24:36'),(2,2,'S3','C2','Weight has been updated, please proceed to payment.',NULL,'Sent','2025-11-29 13:41:45'),(3,3,'S2','C1','Weight has been updated, please proceed to payment.',NULL,'Sent','2025-11-29 14:09:15'),(4,2,'S3','C2','Weight has been updated, please proceed to payment.',NULL,'Sent','2025-11-29 14:10:47'),(5,4,'S2','C2','Weight has been updated, please proceed to payment.',NULL,'Sent','2025-11-29 14:24:09'),(6,5,'S3','C1','Weight has been updated, please proceed to payment.',NULL,'Sent','2025-11-29 14:24:13'),(7,5,'S3','C1','Weight has been updated, please proceed to payment.',NULL,'Sent','2025-11-29 14:29:44'),(8,6,'S1','C2','Weight has been updated, please proceed to payment.',NULL,'Sent','2025-11-29 14:47:08'),(9,6,'S1','C2','Weight has been updated, please proceed to payment.',NULL,'Sent','2025-12-01 01:53:21'),(10,6,'S1','C2','Weight has been updated, please proceed to payment.',NULL,'Sent','2025-12-01 02:34:10'),(11,6,'S1','C2','Weight has been updated, please proceed to payment.',NULL,'Sent','2025-12-01 02:37:47'),(12,6,'S1','C2','Weight has been updated, please proceed to payment.',NULL,'Sent','2025-12-01 02:39:24');
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
INSERT INTO `order_addons` VALUES (1,1),(1,2),(1,3),(1,4),(1,5),(2,1),(2,4),(3,2),(4,1),(5,3),(6,1),(7,4),(8,4),(9,2),(10,1),(12,2),(13,2),(15,2);
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
INSERT INTO `order_fabrics` VALUES (1,1),(1,2),(1,3),(2,1),(2,2),(2,3),(3,1),(4,1),(5,2),(6,2),(7,2),(8,2),(9,2),(10,2),(12,2),(13,3),(14,2),(15,2);
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
  UNIQUE KEY `uq_order_proc_pair` (`OrderID`,`OrderProcStatus`),
  CONSTRAINT `fk_orderprocessing_order` FOREIGN KEY (`OrderID`) REFERENCES `orders` (`OrderID`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=25 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `order_processing`
--

LOCK TABLES `order_processing` WRITE;
/*!40000 ALTER TABLE `order_processing` DISABLE KEYS */;
INSERT INTO `order_processing` VALUES (1,'ODR1451434','Washing','2025-11-29 13:27:48'),(2,'ODR1451434','Drying','2025-11-29 13:28:05'),(3,'ODR5613842','Washing','2025-11-29 13:44:08'),(4,'ODR5613842','Drying','2025-11-29 13:44:31'),(5,'ODR5613842','Folding','2025-11-29 13:45:02'),(6,'ODR9176155','Washing','2025-11-29 14:13:25'),(7,'ODR9020178','Washing','2025-11-29 14:13:26'),(8,'ODR9020178','Drying','2025-11-29 14:13:54'),(9,'ODR9176155','Drying','2025-11-29 14:13:54'),(10,'ODR9176155','Folding','2025-11-29 14:14:28'),(11,'ODR6695789','Washing','2025-11-29 14:26:12'),(12,'ODR1697311','Washing','2025-11-29 14:26:16'),(13,'ODR6695789','Drying','2025-11-29 14:26:26'),(14,'ODR1697311','Drying','2025-11-29 14:26:27'),(15,'ODR1697311','Pressing','2025-11-29 14:26:40'),(16,'ODR6695789','Pressing','2025-11-29 14:26:42'),(17,'ODR8648113','Washing','2025-11-29 14:48:22'),(18,'ODR3832545','Washing','2025-11-29 14:48:31'),(19,'ODR8648113','Drying','2025-11-29 14:48:41'),(20,'ODR3832545','Drying','2025-11-29 14:48:47'),(21,'ODR8648113','Pressing','2025-11-29 14:48:56'),(22,'ODR3832545','Pressing','2025-11-29 14:49:01'),(23,'ODR3832545','Folding','2025-11-29 14:49:10'),(24,'ODR8648113','Folding','2025-11-29 14:49:12');
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
  UNIQUE KEY `uq_order_status_pair` (`OrderID`,`OrderStatus`),
  CONSTRAINT `fk_orderstatus_order` FOREIGN KEY (`OrderID`) REFERENCES `orders` (`OrderID`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=46 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `order_status`
--

LOCK TABLES `order_status` WRITE;
/*!40000 ALTER TABLE `order_status` DISABLE KEYS */;
INSERT INTO `order_status` VALUES (1,'ODR1451434','Pending','2025-11-29 13:16:58'),(2,'ODR1451434','To Weigh','2025-11-29 13:23:55'),(3,'ODR1451434','Processing','2025-11-29 13:27:24'),(4,'ODR1451434','Ready for Delivery','2025-11-29 13:28:23'),(5,'ODR1451434','Completed','2025-11-29 13:29:34'),(6,'ODR5613842','Pending','2025-11-29 13:37:47'),(7,'ODR5613842','To Weigh','2025-11-29 13:40:46'),(8,'ODR5613842','Processing','2025-11-29 13:43:24'),(9,'ODR5613842','Ready for Delivery','2025-11-29 13:45:28'),(10,'ODR5613842','Completed','2025-11-29 13:45:59'),(11,'ODR9176155','To Weigh','2025-11-29 14:02:31'),(12,'ODR9020178','To Weigh','2025-11-29 14:02:38'),(13,'ODR9176155','Processing','2025-11-29 14:12:41'),(14,'ODR9020178','Processing','2025-11-29 14:12:45'),(15,'ODR9020178','Ready for Delivery','2025-11-29 14:14:26'),(16,'ODR9176155','Ready for Delivery','2025-11-29 14:14:52'),(17,'ODR9020178','Completed','2025-11-29 14:15:16'),(18,'ODR9176155','Completed','2025-11-29 14:16:07'),(19,'ODR1697311','Pending','2025-11-29 14:21:04'),(20,'ODR6695789','Pending','2025-11-29 14:21:07'),(21,'ODR6695789','To Weigh','2025-11-29 14:22:55'),(22,'ODR1697311','To Weigh','2025-11-29 14:23:25'),(23,'ODR6695789','Processing','2025-11-29 14:25:10'),(24,'ODR1697311','Processing','2025-11-29 14:25:15'),(25,'ODR1697311','Completed','2025-11-29 14:26:50'),(26,'ODR6695789','Completed','2025-11-29 14:26:52'),(27,'ODR8648113','To Weigh','2025-11-29 14:28:48'),(28,'ODR3832545','To Weigh','2025-11-29 14:28:50'),(29,'ODR8648113','Processing','2025-11-29 14:47:41'),(30,'ODR3832545','Processing','2025-11-29 14:47:51'),(31,'ODR3832545','Completed','2025-11-29 14:49:23'),(32,'ODR8648113','Completed','2025-11-29 14:49:25'),(33,'ODR1750725','To Weigh','2025-12-01 01:48:05'),(34,'ODR9210187','Pending','2025-12-01 01:49:13'),(37,'ODR9435018','Pending','2025-12-01 02:30:44'),(38,'ODR9435018','Cancelled','2025-12-01 02:30:54'),(39,'ODR4126856','To Weigh','2025-12-01 02:33:32'),(40,'ODR4126856','Cancelled','2025-12-01 02:34:19'),(41,'ODR8597115','To Weigh','2025-12-01 02:37:07'),(42,'ODR8597115','Cancelled','2025-12-01 02:37:55'),(43,'ODR3638982','To Weigh','2025-12-01 02:38:42'),(44,'ODR3638982','Processing','2025-12-01 02:40:37'),(45,'ODR1750725','Processing','2025-12-01 02:40:47');
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
  `ShopID` int(11) NOT NULL,
  `OrderCreatedAt` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`OrderID`),
  KEY `fk_order_customer` (`CustID`),
  KEY `fk_order_shop` (`ShopID`),
  CONSTRAINT `fk_order_customer` FOREIGN KEY (`CustID`) REFERENCES `customers` (`CustID`) ON DELETE CASCADE,
  CONSTRAINT `fk_order_shop` FOREIGN KEY (`ShopID`) REFERENCES `laundry_shops` (`ShopID`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `orders`
--

LOCK TABLES `orders` WRITE;
/*!40000 ALTER TABLE `orders` DISABLE KEYS */;
INSERT INTO `orders` VALUES ('ODR1451434','C1',1,'2025-11-29 13:16:58'),('ODR1697311','C2',1,'2025-11-29 14:21:04'),('ODR1750725','C2',1,'2025-12-01 01:48:05'),('ODR3638982','C2',1,'2025-12-01 02:38:42'),('ODR3832545','C2',1,'2025-11-29 14:28:50'),('ODR4126856','C2',1,'2025-12-01 02:33:32'),('ODR5613842','C2',2,'2025-11-29 13:37:47'),('ODR6695789','C1',2,'2025-11-29 14:21:07'),('ODR8597115','C2',1,'2025-12-01 02:37:07'),('ODR8648113','C1',2,'2025-11-29 14:28:48'),('ODR9020178','C2',2,'2025-11-29 14:02:38'),('ODR9176155','C1',1,'2025-11-29 14:02:30'),('ODR9210187','C2',1,'2025-12-01 01:49:13'),('ODR9435018','C2',1,'2025-12-01 02:30:44');
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
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `otps`
--

LOCK TABLES `otps` WRITE;
/*!40000 ALTER TABLE `otps` DISABLE KEYS */;
INSERT INTO `otps` VALUES (11,'C3','259209','2025-11-30 15:44:58','2025-11-30 07:34:58'),(13,'C2','731267','2025-12-02 09:30:44','2025-12-02 01:20:44');
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
-- Table structure for table `platform_growth_metrics`
--

DROP TABLE IF EXISTS `platform_growth_metrics`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `platform_growth_metrics` (
  `MonthYear` char(7) NOT NULL,
  `NewShops` int(11) DEFAULT 0,
  `ChurnedShops` int(11) DEFAULT 0,
  `TotalActiveShops` int(11) DEFAULT NULL,
  `MonthlyRevenue` decimal(12,2) DEFAULT NULL,
  `AnalyzedAt` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`MonthYear`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `platform_growth_metrics`
--

LOCK TABLES `platform_growth_metrics` WRITE;
/*!40000 ALTER TABLE `platform_growth_metrics` DISABLE KEYS */;
INSERT INTO `platform_growth_metrics` VALUES ('2025-11',2,0,2,0.00,'2025-11-29 13:10:00');
/*!40000 ALTER TABLE `platform_growth_metrics` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `service_gap_analysis`
--

DROP TABLE IF EXISTS `service_gap_analysis`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `service_gap_analysis` (
  `SvcName` varchar(50) NOT NULL,
  `PlatformOrderCount` int(11) NOT NULL,
  `OfferingShopCount` int(11) NOT NULL,
  `GapScore` decimal(10,2) DEFAULT NULL,
  `AnalyzedAt` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`SvcName`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `service_gap_analysis`
--

LOCK TABLES `service_gap_analysis` WRITE;
/*!40000 ALTER TABLE `service_gap_analysis` DISABLE KEYS */;
INSERT INTO `service_gap_analysis` VALUES ('Full Service',0,1,0.00,'2025-11-29 13:09:59'),('Wash & Dry',0,2,0.00,'2025-11-29 13:10:00'),('Wash, Dry, & Fold',0,2,0.00,'2025-11-29 13:10:00'),('Wash, Dry, & Press',0,2,0.00,'2025-11-29 13:10:00');
/*!40000 ALTER TABLE `service_gap_analysis` ENABLE KEYS */;
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
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `services`
--

LOCK TABLES `services` WRITE;
/*!40000 ALTER TABLE `services` DISABLE KEYS */;
INSERT INTO `services` VALUES (1,'Wash & Dry'),(2,'Wash, Dry, & Fold'),(3,'Wash, Dry, & Press'),(4,'Full Service');
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
INSERT INTO `shop_add_ons` VALUES (1,1,20.00),(1,2,22.00),(1,3,60.00),(1,4,25.00),(1,5,50.00),(2,1,20.00),(2,4,25.00),(3,1,25.00);
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
  `ShopID` int(11) NOT NULL,
  `DlvryTypeID` int(11) NOT NULL,
  PRIMARY KEY (`ShopID`,`DlvryTypeID`),
  KEY `fk_shopdelivery_type` (`DlvryTypeID`),
  CONSTRAINT `fk_shopdelivery_shop` FOREIGN KEY (`ShopID`) REFERENCES `laundry_shops` (`ShopID`) ON DELETE CASCADE,
  CONSTRAINT `fk_shopdelivery_type` FOREIGN KEY (`DlvryTypeID`) REFERENCES `delivery_types` (`DlvryTypeID`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `shop_delivery_options`
--

LOCK TABLES `shop_delivery_options` WRITE;
/*!40000 ALTER TABLE `shop_delivery_options` DISABLE KEYS */;
INSERT INTO `shop_delivery_options` VALUES (1,1),(1,2),(1,3),(1,4),(2,1),(2,2),(2,3),(2,4),(3,2);
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
  UNIQUE KEY `ShopID` (`ShopID`),
  CONSTRAINT `fk_shop_distance` FOREIGN KEY (`ShopID`) REFERENCES `laundry_shops` (`ShopID`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `shop_distance`
--

LOCK TABLES `shop_distance` WRITE;
/*!40000 ALTER TABLE `shop_distance` DISABLE KEYS */;
INSERT INTO `shop_distance` VALUES (1,10.33180530,123.90015465),(2,10.32550800,123.97534700),(3,10.28810115,123.95416692),(4,10.33180530,123.90015465);
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
INSERT INTO `shop_fabrics` VALUES (1,1),(1,2),(1,3),(2,1),(2,2),(2,3),(3,1);
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
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `shop_own_service`
--

LOCK TABLES `shop_own_service` WRITE;
/*!40000 ALTER TABLE `shop_own_service` DISABLE KEYS */;
INSERT INTO `shop_own_service` VALUES (1,2,20.00,5,10.00,'Active'),(2,3,30.00,3,10.00,'Active');
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
INSERT INTO `shop_owners` VALUES ('O1','Shop Owner 1','09438456783','Shop Owner 1 Address'),('O2','Shop Owner 2','09418525426','Shop Owner 2 Address'),('O3','Test Userrrr','0932765476','Test User Addressoahgga'),('O4','Shop Owner 3','09418525426','Shop Owner 3 Address');
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
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `shop_rate_stats`
--

LOCK TABLES `shop_rate_stats` WRITE;
/*!40000 ALTER TABLE `shop_rate_stats` DISABLE KEYS */;
INSERT INTO `shop_rate_stats` VALUES (1,1,5.0,'2025-11-29 13:30:02'),(2,2,5.0,'2025-11-29 13:46:39'),(3,1,5.0,'2025-11-29 14:16:51'),(4,2,5.0,'2025-11-29 14:17:26'),(5,1,5.0,'2025-11-29 14:27:17'),(6,2,5.0,'2025-11-29 14:27:24'),(7,1,4.8,'2025-11-29 14:50:25'),(8,2,4.5,'2025-11-29 14:51:06');
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
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `shop_rates`
--

LOCK TABLES `shop_rates` WRITE;
/*!40000 ALTER TABLE `shop_rates` DISABLE KEYS */;
INSERT INTO `shop_rates` VALUES (1,1,4.8),(2,2,4.5);
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
INSERT INTO `shop_services` VALUES (1,1,23.00,3),(1,2,24.00,3),(1,3,25.00,2),(1,4,27.00,4),(2,1,23.00,2),(2,2,26.00,2),(2,3,30.00,3),(2,4,32.00,3),(3,1,40.00,3);
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
  UNIQUE KEY `StaffID` (`StaffID`),
  CONSTRAINT `fk_staff_info` FOREIGN KEY (`StaffID`) REFERENCES `staffs` (`StaffID`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `staff_infos`
--

LOCK TABLES `staff_infos` WRITE;
/*!40000 ALTER TABLE `staff_infos` DISABLE KEYS */;
INSERT INTO `staff_infos` VALUES (1,'S1',26,'Wash N Dry Staff Address','09765423444',120400.00),(2,'S2',24,'Juan Wash N Dry Staff Address','09765423444',150500.00),(3,'S3',25,'Sparklean Staff Address','09876543555',450200.00),(4,'S4',21,'Spark Klean Staff','09765423444',350600.00);
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
INSERT INTO `staffs` VALUES ('S1','Wash N Dry Staff','Cashier',1),('S2','Juan Wash N Dry Staff','Cashier',1),('S3','Sparklean Staff','Washer',2),('S4','Spark Klean Staff','Cashier',2);
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
INSERT INTO `systemconfig` VALUES ('MAINTENANCE_MODE','true');
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
) ENGINE=InnoDB AUTO_INCREMENT=152 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_logs`
--

LOCK TABLES `user_logs` WRITE;
/*!40000 ALTER TABLE `user_logs` DISABLE KEYS */;
INSERT INTO `user_logs` VALUES (1,'A1','Admin','Login','Direct login success','2025-11-29 12:12:17'),(3,'O1','Shop Owner','Shop Owner Creation','New Shop Owner account created: O1','2025-11-29 12:13:26'),(4,'O1','Shop Owner','Login','Direct login success','2025-11-29 12:15:22'),(5,'S1','Cashier','Staff Creation','New Cashier: Wash N Dry Staff','2025-11-29 12:21:38'),(6,'S2','Cashier','Staff Creation','New Cashier: Juan Wash N Dry Staff','2025-11-29 12:22:50'),(7,'O2','Shop Owner','Shop Owner Creation','New Shop Owner account created: O2','2025-11-29 12:23:33'),(8,'S3','Washer','Staff Creation','New Washer: Sparklean Staff','2025-11-29 12:31:00'),(9,'S4','Cashier','Staff Creation','New Cashier: Spark Klean Staff','2025-11-29 12:31:55'),(10,'O2','Shop Owner','Login','Direct login success','2025-11-29 12:33:41'),(11,'A1','Admin','Login','Direct login success','2025-11-29 12:53:49'),(12,'O1','Shop Owner','Login','Direct login success','2025-11-29 12:54:12'),(13,'C1','Customer','Sign-up','User created via Google','2025-11-29 12:54:41'),(14,'C1','Customer','Login','OTP Verified Success','2025-11-29 12:54:52'),(15,'C1','Customer','Profile Update','Customer updated profile','2025-11-29 12:55:39'),(16,'C1','Customer','Password Change','User set/updated password','2025-11-29 12:55:39'),(17,'C1','Customer','Password Reset','OTP Sent','2025-11-29 12:56:12'),(18,'C1','Customer','Password Reset','Success','2025-11-29 12:56:37'),(19,'C1','Customer','Login Failed','Invalid password','2025-11-29 12:57:08'),(20,'C1','Customer','Login','OTP Verified Success','2025-11-29 12:57:33'),(21,'C2','Customer','Sign-up','User created via Google','2025-11-29 13:02:48'),(22,'C2','Customer','Login','OTP Verified Success','2025-11-29 13:03:30'),(23,'C2','Customer','Password Reset','OTP Sent','2025-11-29 13:05:23'),(24,'C2','Customer','Password Reset','Success','2025-11-29 13:05:52'),(25,'C2','Customer','Login','OTP Verified Success','2025-11-29 13:06:23'),(26,'C2','Customer','Profile Update','Customer updated profile','2025-11-29 13:07:05'),(27,'C2','Customer','Password Change','User set/updated password','2025-11-29 13:07:06'),(28,'C1','Customer','Login','OTP Verified Success','2025-11-29 13:11:41'),(29,'C1','Customer','Create Order','New order created: ODR1451434','2025-11-29 13:16:58'),(30,'S2','Staff','Login','Direct login success','2025-11-29 13:19:57'),(31,'S1','Staff','Login','Direct login success','2025-11-29 13:21:36'),(32,'S1','Cashier','Confirm Delivery Pay','Delivery payment confirmed for Order ODR1451434','2025-11-29 13:22:47'),(33,'S1','Staff','Delivery Booking','Proof uploaded for Order ODR1451434. Status: Rider Booked To Pick-up','2025-11-29 13:23:30'),(34,'S1','Staff','Update Delivery Status','ODR1451434: Delivered In Shop','2025-11-29 13:23:55'),(35,'S1','Staff','Update Weight','Order ODR1451434 weight updated to 6kg.','2025-11-29 13:24:36'),(36,'C1','Customer','Login','OTP Verified Success','2025-11-29 13:25:57'),(37,'S1','Cashier','Confirm Payment','Service payment confirmed ODR1451434','2025-11-29 13:27:24'),(38,'S1','Staff','Update Processing','Order ODR1451434: Washing','2025-11-29 13:27:48'),(39,'S1','Staff','Update Processing','Order ODR1451434: Drying','2025-11-29 13:28:05'),(40,'S1','Staff','Update Delivery Status','ODR1451434: For Delivery','2025-11-29 13:28:23'),(41,'S1','Staff','Delivery Booking','Proof uploaded for Order ODR1451434. Status: Rider Booked For Delivery','2025-11-29 13:29:12'),(42,'S1','Staff','Update Delivery Status','ODR1451434: Delivered To Customer','2025-11-29 13:29:34'),(43,'C2','Customer','Create Order','New order created: ODR5613842','2025-11-29 13:37:47'),(44,'S4','Staff','Login','Direct login success','2025-11-29 13:39:09'),(45,'S3','Staff','Login','Direct login success','2025-11-29 13:39:32'),(46,'S3','Cashier','Confirm Delivery Pay','Delivery payment confirmed for Order ODR5613842','2025-11-29 13:39:54'),(47,'S3','Staff','Update Delivery Status','ODR5613842: Arrived at Customer','2025-11-29 13:40:46'),(48,'S3','Staff','Update Weight','Order ODR5613842 weight updated to 9kg.','2025-11-29 13:41:45'),(49,'S3','Cashier','Confirm Payment','Service payment confirmed ODR5613842','2025-11-29 13:43:24'),(50,'S3','Staff','Update Processing','Order ODR5613842: Washing','2025-11-29 13:44:08'),(51,'S3','Staff','Update Processing','Order ODR5613842: Drying','2025-11-29 13:44:31'),(52,'S3','Staff','Update Processing','Order ODR5613842: Folding','2025-11-29 13:45:02'),(53,'S3','Staff','Update Delivery Status','ODR5613842: For Delivery','2025-11-29 13:45:28'),(54,'S3','Staff','Update Delivery Status','ODR5613842: Delivered To Customer','2025-11-29 13:45:59'),(55,'C2','Customer','Login','OTP Verified Success','2025-11-29 13:47:44'),(56,'C1','Customer','Login','OTP Verified Success','2025-11-29 13:53:35'),(57,'A1','Admin','Login','Direct login success','2025-11-29 14:01:00'),(58,'C1','Customer','Create Order','New order created: ODR9176155','2025-11-29 14:02:31'),(59,'C2','Customer','Create Order','New order created: ODR9020178','2025-11-29 14:02:38'),(60,'O1','Shop Owner','Login','Direct login success','2025-11-29 14:07:29'),(61,'S2','Staff','Login','Direct login success','2025-11-29 14:08:26'),(62,'S2','Staff','Update Weight','Order ODR9176155 weight updated to 9.5kg.','2025-11-29 14:09:15'),(63,'S3','Staff','Update Weight','Order ODR9020178 weight updated to 10.5kg.','2025-11-29 14:10:47'),(64,'S2','Cashier','Confirm Payment','Service payment confirmed ODR9176155','2025-11-29 14:12:41'),(65,'S3','Cashier','Confirm Payment','Service payment confirmed ODR9020178','2025-11-29 14:12:45'),(66,'S2','Staff','Update Processing','Order ODR9176155: Washing','2025-11-29 14:13:25'),(67,'S3','Staff','Update Processing','Order ODR9020178: Washing','2025-11-29 14:13:26'),(68,'S3','Staff','Update Processing','Order ODR9020178: Drying','2025-11-29 14:13:54'),(69,'S2','Staff','Update Processing','Order ODR9176155: Drying','2025-11-29 14:13:54'),(70,'S3','Staff','Update Delivery Status','ODR9020178: For Delivery','2025-11-29 14:14:26'),(71,'S2','Staff','Update Processing','Order ODR9176155: Folding','2025-11-29 14:14:28'),(72,'S2','Staff','Update Delivery Status','ODR9176155: For Delivery','2025-11-29 14:14:52'),(73,'S3','Staff','Update Delivery Status','ODR9020178: Delivered To Customer','2025-11-29 14:15:16'),(74,'S2','Staff','Delivery Booking','Proof uploaded for Order ODR9176155. Status: Rider Booked For Delivery','2025-11-29 14:15:28'),(75,'S2','Staff','Update Delivery Status','ODR9176155: Delivered To Customer','2025-11-29 14:16:07'),(76,'C2','Customer','Create Order','New order created: ODR1697311','2025-11-29 14:21:04'),(77,'C1','Customer','Create Order','New order created: ODR6695789','2025-11-29 14:21:07'),(78,'S2','Cashier','Confirm Delivery Pay','Delivery payment confirmed for Order ODR1697311','2025-11-29 14:21:49'),(79,'S3','Cashier','Confirm Delivery Pay','Delivery payment confirmed for Order ODR6695789','2025-11-29 14:21:57'),(80,'S2','Staff','Delivery Booking','Proof uploaded for Order ODR1697311. Status: Rider Booked To Pick-up','2025-11-29 14:22:55'),(81,'S3','Staff','Update Delivery Status','ODR6695789: Arrived at Customer','2025-11-29 14:22:55'),(82,'S2','Staff','Update Delivery Status','ODR1697311: Delivered In Shop','2025-11-29 14:23:25'),(83,'S2','Staff','Update Weight','Order ODR1697311 weight updated to 8.2kg.','2025-11-29 14:24:09'),(84,'S3','Staff','Update Weight','Order ODR6695789 weight updated to 8.9kg.','2025-11-29 14:24:13'),(85,'S3','Cashier','Confirm Payment','Service payment confirmed ODR6695789','2025-11-29 14:25:10'),(86,'S2','Cashier','Confirm Payment','Service payment confirmed ODR1697311','2025-11-29 14:25:15'),(87,'S3','Staff','Update Processing','Order ODR6695789: Washing','2025-11-29 14:26:12'),(88,'S2','Staff','Update Processing','Order ODR1697311: Washing','2025-11-29 14:26:16'),(89,'S3','Staff','Update Processing','Order ODR6695789: Drying','2025-11-29 14:26:26'),(90,'S2','Staff','Update Processing','Order ODR1697311: Drying','2025-11-29 14:26:27'),(91,'S2','Staff','Update Processing','Order ODR1697311: Pressing','2025-11-29 14:26:40'),(92,'S3','Staff','Update Processing','Order ODR6695789: Pressing','2025-11-29 14:26:42'),(93,'S2','Staff','Update Order Status','Order ODR1697311 status: Completed','2025-11-29 14:26:50'),(94,'S3','Staff','Update Order Status','Order ODR6695789 status: Completed','2025-11-29 14:26:52'),(95,'C1','Customer','Create Order','New order created: ODR8648113','2025-11-29 14:28:48'),(96,'C2','Customer','Create Order','New order created: ODR3832545','2025-11-29 14:28:50'),(97,'S3','Staff','Update Weight','Order ODR8648113 weight updated to 15.5kg.','2025-11-29 14:29:44'),(98,'S1','Staff','Login','Direct login success','2025-11-29 14:45:23'),(99,'S1','Staff','Update Weight','Order ODR3832545 weight updated to 18kg.','2025-11-29 14:47:08'),(100,'S3','Cashier','Confirm Payment','Service payment confirmed ODR8648113','2025-11-29 14:47:41'),(101,'S1','Cashier','Confirm Payment','Service payment confirmed ODR3832545','2025-11-29 14:47:51'),(102,'S3','Staff','Update Processing','Order ODR8648113: Washing','2025-11-29 14:48:22'),(103,'S1','Staff','Update Processing','Order ODR3832545: Washing','2025-11-29 14:48:31'),(104,'S3','Staff','Update Processing','Order ODR8648113: Drying','2025-11-29 14:48:41'),(105,'S1','Staff','Update Processing','Order ODR3832545: Drying','2025-11-29 14:48:47'),(106,'S3','Staff','Update Processing','Order ODR8648113: Pressing','2025-11-29 14:48:56'),(107,'S1','Staff','Update Processing','Order ODR3832545: Pressing','2025-11-29 14:49:01'),(108,'S1','Staff','Update Processing','Order ODR3832545: Folding','2025-11-29 14:49:10'),(109,'S3','Staff','Update Processing','Order ODR8648113: Folding','2025-11-29 14:49:12'),(110,'S1','Staff','Update Order Status','Order ODR3832545 status: Completed','2025-11-29 14:49:23'),(111,'S3','Staff','Update Order Status','Order ODR8648113 status: Completed','2025-11-29 14:49:25'),(112,'O1','Admin','Data Security','Generated system backup: laundrolink_db_2025-11-29T15-08-23-746Z.sql','2025-11-29 15:08:37'),(113,'O1','Admin','Data Security','Downloaded backup file: laundrolink_db_2025-11-29T15-08-23-746Z.sql','2025-11-29 15:08:37'),(114,'C3','Customer','Sign-up','User created via Google','2025-11-30 07:34:58'),(115,'S1','Staff','Login','Direct login success','2025-12-01 01:39:09'),(116,'S4','Staff','Login','Direct login success','2025-12-01 01:39:41'),(117,'C2','Customer','Login','OTP Verified Success','2025-12-01 01:46:45'),(118,'C2','Customer','Create Order','New order created: ODR1750725','2025-12-01 01:48:05'),(119,'C2','Customer','Create Order','New order created: ODR9210187','2025-12-01 01:49:13'),(120,'S1','Staff','Login','Direct login success','2025-12-01 01:50:04'),(121,'S1','Staff','Login','Direct login success','2025-12-01 01:51:53'),(122,'S1','Cashier','Confirm Delivery Pay','Delivery payment confirmed for Order ODR9210187','2025-12-01 01:52:36'),(123,'S1','Staff','Update Weight','Order ODR1750725 weight updated to 5.5kg.','2025-12-01 01:53:21'),(124,'C2','Customer','Create Order','New order created: ODR4231360','2025-12-01 02:04:15'),(125,'C2','Customer','Cancel Order','Order ODR4231360 cancelled.','2025-12-01 02:14:56'),(126,'C2','Customer','Create Order','New order created: ODR9435018','2025-12-01 02:30:44'),(127,'C2','Customer','Cancel Order','Order ODR9435018 cancelled.','2025-12-01 02:30:54'),(128,'C2','Customer','Create Order','New order created: ODR4126856','2025-12-01 02:33:32'),(129,'S1','Staff','Update Weight','Order ODR4126856 weight updated to 6.5kg.','2025-12-01 02:34:10'),(130,'C2','Customer','Cancel Order','Order ODR4126856 cancelled.','2025-12-01 02:34:19'),(131,'C2','Customer','Create Order','New order created: ODR8597115','2025-12-01 02:37:07'),(132,'S1','Staff','Update Weight','Order ODR8597115 weight updated to 58kg.','2025-12-01 02:37:47'),(133,'C2','Customer','Cancel Order','Order ODR8597115 cancelled.','2025-12-01 02:37:55'),(134,'C2','Customer','Create Order','New order created: ODR3638982','2025-12-01 02:38:42'),(135,'S1','Staff','Update Weight','Order ODR3638982 weight updated to 5kg.','2025-12-01 02:39:24'),(136,'S1','Cashier','Confirm Payment','Service payment confirmed ODR3638982','2025-12-01 02:40:37'),(137,'S1','Cashier','Confirm Payment','Service payment confirmed ODR1750725','2025-12-01 02:40:47'),(138,'A1','Admin','Login','Direct login success','2025-12-01 15:10:14'),(139,'A1','Admin','Login','Direct login success','2025-12-01 15:19:28'),(140,'O2','Shop Owner','Login','Direct login success','2025-12-01 17:24:28'),(141,'A2','Admin','Login','Direct login success','2025-12-02 00:24:08'),(142,'O3','Shop Owner','Shop Owner Creation','New Shop Owner account created: O3','2025-12-02 00:24:48'),(143,'O3','Shop Owner','User Status Change','Shop Owner O3 Deactivated','2025-12-02 00:31:31'),(144,'O3','Shop Owner','User Status Change','Shop Owner O3 Reactivated','2025-12-02 00:48:12'),(145,'O3','Shop Owner','Owner Update','Shop Owner Test Userrrr details updated','2025-12-02 00:48:26'),(146,'O3','Shop Owner','Owner Update','Shop Owner Test Userrrr details updated','2025-12-02 00:48:26'),(147,'O3','Shop Owner','Owner Update','Shop Owner Test Userrrr details updated','2025-12-02 00:48:26'),(148,'O1','Shop Owner','Login','Direct login success','2025-12-02 01:25:18'),(149,'O4','Shop Owner','Shop Owner Creation','New Shop Owner account created: O4','2025-12-02 02:17:12'),(150,'O4','Shop Owner','User Status Change','Shop Owner O4 Deactivated','2025-12-02 02:19:35'),(151,'O1','Admin','System Config','Maintenance mode set to: true','2025-12-02 02:35:39');
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
INSERT INTO `users` VALUES ('A1','mj1','mj1','Admin','2025-09-15 02:00:01',1),('A2','juriel1','juriel1','Admin','2025-09-15 02:00:02',1),('A3','kezhea1','kezhea1','Admin','2025-09-15 02:00:03',1),('A4','jasper1','jasper1','Admin','2025-09-15 02:00:04',1),('C1','jhongulane126@gmail.com','$2b$10$83ZinB7zvVxAQui9l7KKC.arnzJFqQ4QYV2DJCYJhuvL548jpntrC','Customer','2025-11-29 12:54:40',1),('C2','jhongulane125@gmail.com','$2b$10$Kody/bjCVyvgJP8DvlGpzuhIWiLKIvOB8sHzrA6BWrHXs3O.oEpIS','Customer','2025-11-29 13:02:48',1),('C3','jhongulane123@gmail.com',NULL,'Customer','2025-11-30 07:34:58',1),('O1','shopowner1@gmail.com','$2b$10$EM3B0WeuuieFrI/CxcmYAetfgIPl8fRZAAQVoGzqyaXsJ6AufUlQe','Shop Owner','2025-11-29 12:13:26',1),('O2','shopowner2@gmail.com','$2b$10$YFrfqAdpuqMJ4FipoYErt.pjXH49/jF/Ll4yrO4uHUuQj9L611eh6','Shop Owner','2025-11-29 12:23:33',1),('O3','testuser@gmail.com','$2b$10$VbXxKtji/ESPV/C1fI5J8u/jmszlNmlJ6ApStenCLr3TXuzTxbHCC','Shop Owner','2025-12-02 00:24:48',1),('O4','shopownertest@gmail.com','$2b$10$H9WyXOsLQc9SqSrerwA.geXPYhHncoKLQwkDQPHgKeUulSWZ5Re5y','Shop Owner','2025-12-02 02:17:12',0),('S1','wash1','$2b$10$r2Fi8v0A/XJCEedHTKns0eIlRIQ1IuhD.JJynhrdne/ttRkEaTn1e','Staff','2025-11-29 12:21:38',1),('S2','juan1','$2b$10$uNJGIW0ngplUeuGud3t5vu5D2WcDx5H0fcqLlyZAGf/RvP/Kgk64i','Staff','2025-11-29 12:22:50',1),('S3','sparklean1','$2b$10$vq.vLi2iFulr4jUhM.xiR.dc8TgYmlpUgABGJbF8FV3KtKWbrIiLS','Staff','2025-11-29 12:31:00',1),('S4','spark1','$2b$10$n702TSNQEoB5LSXgfuOlpuyV7TyLcwAwB1tUVmF1Gl3SGrGtG2xre','Staff','2025-11-29 12:31:55',1);
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

-- Dump completed on 2025-12-02 10:36:55
