/*
  Warnings:

  - The values [POSTER] on the enum `UserRole` will be removed. If these variants are still used in the database, this will fail.
  - You are about to drop the column `taskId` on the `Review` table. All the data in the column will be lost.
  - You are about to drop the `Bid` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `Task` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `TaskPhoto` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `TaskQuestion` table. If the table is not empty, all the data it contains will be lost.
  - A unique constraint covering the columns `[jobId,reviewerId]` on the table `Review` will be added. If there are existing duplicate values, this will fail.
  - Added the required column `jobId` to the `Review` table without a default value. This is not possible if the table is not empty.

*/
-- CreateEnum
CREATE TYPE "JobStatus" AS ENUM ('DRAFT', 'PUBLISHED', 'OFFERING', 'ACCEPTED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED', 'DISPUTED');

-- CreateEnum
CREATE TYPE "OfferStatus" AS ENUM ('ACTIVE', 'WITHDRAWN', 'ACCEPTED', 'DECLINED', 'EXPIRED');

-- AlterEnum
BEGIN;
CREATE TYPE "UserRole_new" AS ENUM ('CLIENT', 'TASKER', 'ADMIN', 'SUPER_ADMIN');
ALTER TABLE "User" ALTER COLUMN "role" TYPE "UserRole_new" USING ("role"::text::"UserRole_new");
ALTER TYPE "UserRole" RENAME TO "UserRole_old";
ALTER TYPE "UserRole_new" RENAME TO "UserRole";
DROP TYPE "public"."UserRole_old";
COMMIT;

-- DropForeignKey
ALTER TABLE "Bid" DROP CONSTRAINT "Bid_taskId_fkey";

-- DropForeignKey
ALTER TABLE "Bid" DROP CONSTRAINT "Bid_taskerId_fkey";

-- DropForeignKey
ALTER TABLE "Task" DROP CONSTRAINT "Task_categoryId_fkey";

-- DropForeignKey
ALTER TABLE "Task" DROP CONSTRAINT "Task_countryCode_fkey";

-- DropForeignKey
ALTER TABLE "Task" DROP CONSTRAINT "Task_posterId_fkey";

-- DropForeignKey
ALTER TABLE "TaskPhoto" DROP CONSTRAINT "TaskPhoto_taskId_fkey";

-- DropForeignKey
ALTER TABLE "TaskQuestion" DROP CONSTRAINT "TaskQuestion_taskId_fkey";

-- DropIndex
DROP INDEX "Review_taskId_idx";

-- DropIndex
DROP INDEX "Review_taskId_reviewerId_key";

-- AlterTable
ALTER TABLE "Review" DROP COLUMN "taskId",
ADD COLUMN     "jobId" TEXT NOT NULL;

-- DropTable
DROP TABLE "Bid";

-- DropTable
DROP TABLE "Task";

-- DropTable
DROP TABLE "TaskPhoto";

-- DropTable
DROP TABLE "TaskQuestion";

-- DropEnum
DROP TYPE "BidStatus";

-- DropEnum
DROP TYPE "TaskStatus";

-- CreateTable
CREATE TABLE "Job" (
    "id" TEXT NOT NULL,
    "clientId" TEXT NOT NULL,
    "categoryId" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "countryCode" TEXT NOT NULL DEFAULT 'AU',
    "transactionType" "CategoryType" NOT NULL,
    "budgetCents" INTEGER NOT NULL,
    "addressLine" TEXT,
    "suburb" TEXT,
    "postcode" TEXT,
    "latitude" DOUBLE PRECISION,
    "longitude" DOUBLE PRECISION,
    "scheduledAt" TIMESTAMP(3),
    "durationHours" INTEGER,
    "status" "JobStatus" NOT NULL DEFAULT 'DRAFT',
    "embedding" vector(1536),
    "embeddingHash" TEXT,
    "extractedFields" JSONB,
    "publishedAt" TIMESTAMP(3),
    "acceptedAt" TIMESTAMP(3),
    "completedAt" TIMESTAMP(3),
    "cancelledAt" TIMESTAMP(3),
    "deletedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Job_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "JobPhoto" (
    "id" TEXT NOT NULL,
    "jobId" TEXT NOT NULL,
    "blobUrl" TEXT NOT NULL,
    "altText" TEXT,
    "width" INTEGER,
    "height" INTEGER,
    "exifJson" JSONB,
    "moderation" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "JobPhoto_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "JobQuestion" (
    "id" TEXT NOT NULL,
    "jobId" TEXT NOT NULL,
    "askedById" TEXT NOT NULL,
    "question" TEXT NOT NULL,
    "answer" TEXT,
    "answeredAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "JobQuestion_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Offer" (
    "id" TEXT NOT NULL,
    "jobId" TEXT NOT NULL,
    "taskerId" TEXT NOT NULL,
    "amountCents" INTEGER NOT NULL,
    "message" TEXT,
    "estimatedAt" TIMESTAMP(3),
    "status" "OfferStatus" NOT NULL DEFAULT 'ACTIVE',
    "expiresAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Offer_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "Job_clientId_idx" ON "Job"("clientId");

-- CreateIndex
CREATE INDEX "Job_categoryId_idx" ON "Job"("categoryId");

-- CreateIndex
CREATE INDEX "Job_countryCode_idx" ON "Job"("countryCode");

-- CreateIndex
CREATE INDEX "Job_status_idx" ON "Job"("status");

-- CreateIndex
CREATE INDEX "Job_scheduledAt_idx" ON "Job"("scheduledAt");

-- CreateIndex
CREATE INDEX "Job_deletedAt_idx" ON "Job"("deletedAt");

-- CreateIndex
CREATE INDEX "Job_publishedAt_idx" ON "Job"("publishedAt");

-- CreateIndex
CREATE INDEX "JobPhoto_jobId_idx" ON "JobPhoto"("jobId");

-- CreateIndex
CREATE INDEX "JobQuestion_jobId_idx" ON "JobQuestion"("jobId");

-- CreateIndex
CREATE INDEX "JobQuestion_askedById_idx" ON "JobQuestion"("askedById");

-- CreateIndex
CREATE INDEX "Offer_jobId_idx" ON "Offer"("jobId");

-- CreateIndex
CREATE INDEX "Offer_taskerId_idx" ON "Offer"("taskerId");

-- CreateIndex
CREATE INDEX "Offer_status_idx" ON "Offer"("status");

-- CreateIndex
CREATE INDEX "Offer_expiresAt_idx" ON "Offer"("expiresAt");

-- CreateIndex
CREATE UNIQUE INDEX "Offer_jobId_taskerId_key" ON "Offer"("jobId", "taskerId");

-- CreateIndex
CREATE INDEX "Review_jobId_idx" ON "Review"("jobId");

-- CreateIndex
CREATE UNIQUE INDEX "Review_jobId_reviewerId_key" ON "Review"("jobId", "reviewerId");

-- AddForeignKey
ALTER TABLE "Job" ADD CONSTRAINT "Job_clientId_fkey" FOREIGN KEY ("clientId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Job" ADD CONSTRAINT "Job_categoryId_fkey" FOREIGN KEY ("categoryId") REFERENCES "Category"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Job" ADD CONSTRAINT "Job_countryCode_fkey" FOREIGN KEY ("countryCode") REFERENCES "Country"("code") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "JobPhoto" ADD CONSTRAINT "JobPhoto_jobId_fkey" FOREIGN KEY ("jobId") REFERENCES "Job"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "JobQuestion" ADD CONSTRAINT "JobQuestion_jobId_fkey" FOREIGN KEY ("jobId") REFERENCES "Job"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "JobQuestion" ADD CONSTRAINT "JobQuestion_askedById_fkey" FOREIGN KEY ("askedById") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Offer" ADD CONSTRAINT "Offer_jobId_fkey" FOREIGN KEY ("jobId") REFERENCES "Job"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Offer" ADD CONSTRAINT "Offer_taskerId_fkey" FOREIGN KEY ("taskerId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
