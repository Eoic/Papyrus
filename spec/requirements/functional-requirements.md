---
icon: function
layout:
  title:
    visible: true
  description:
    visible: false
  tableOfContents:
    visible: true
  outline:
    visible: true
  pagination:
    visible: true
---

# Functional requirements

## 1. User management

* FR-1.1. User can create an account using and email address and a password.&#x20;
* FR-1.2. User can login to the system using an email and and password.
* FR-1.3. User can login to the system using their Google account.
* FR-1.4. User can login to the system in offline mode without providing any credentials, without requiring active internet connection.
* FR-1.5. Use can restore their account via password recovery link.

## 2. Book management

* FR-2.1. User can convert existing book file into one of the following formats: EPUB, PDF, MOBI.
* FR-2.2. User can manually edit book metadata that was parsed when adding a book to the system.
* FR-2.3. User can add and remove book metadata fields in the existing book.
* FR-2.4. User can export selected book files from the system.
* FR-2.5. User can export data about uploaded books from the system in a structured, human readable format.
* FR-2.6. User can import new book records to the system from a file.
* FR-2.7. System allows a full-text search capabilities to search book contents.&#x20;
* FR-2.8. System allow searching for books using the following properties: book metadata values, tags, categories, predefined complex filters and text contents (full-text search).
* FR-2.9. A user can create shelves that group books into categories.
* FR-2.10. A user can assign tags to a book, each consisting of a title and a color. A book can have between 0 to 10 unique tags.
* FR-2.11. A user can create complex filters via a query language, such as "Release date between 1950 and 2000."

## 3. Integrated viewer

* FR-3.1: A user can use an integrated e-book viewer for reading book contents.
* FR-3.2: A user can customize viewer font, font size, spacing, colors, and layout.
* FR-3.3: A user can create and save custom reading profiles (look-and-feel settings).

## 4. Annotations and notes

* FR-4.1. A user can create annotation by selecting book text in the viewer. Annotation consists of selected, color and an optional note.
* FR-4.5. A user can create one or more notes for each book in the library. The difference between a note and an annotation is that a note if free-style text not attached to the content in the book.&#x20;

## 5. Progress tracking

* FR-5.1. A user can view reading progress that includes:
  * Time spent reading.
  * Number to books added, in progress, and completed.
  * Number of pages pages read.
  * Time spend reading per book.
  * Reading velocity per book (how much time was spent relative to page count).
* FR-5.2. A user can choose to filter the statistics based on the following attributes:
  * **Time frame:**
    * **Last year**: view statistics for activities conducted in the previous calendar year.
    * **Last month**: focus on engagements recorded in the past month.
    * **Last week**: analyze the activities logged in the previous week.
    * **Custom interval**: define a specific start and end date to examine data within a chosen time frame.
    * **Time interval**: select from predefined intervals like the past 7 days, 30 days, or user-defined periods for a customized view.
  * **Book selection:**
    * **Selected books**: narrow down the statistics to a specific selection of books.
    * **All books**: broaden the view to encompass all books within the user's library.
* FR-5.3. The system synchronizes reading progress across all logged-in devices.

## 6. Goal management

* FR-6.1. User can create time-based reading goals such as "Read `N` books in `M` months.", where `N`and `M`are non negative integer values. Goal templates are predefined and selected can be selected by the user from a list.
* FR-6.2. User can manually update goal values.
* FR-6.3. System can automatically update goal progress values, start and end goals and display completion status.

## 7. Storage and synchronization

* FR-7.1. The system allows a user to choose a file storage method: device, self-hosted server, or personal cloud storage (e.g., Google Drive).
* FR-7.2. A user can upload a book file by selecting it from the device.
* FR-7.3. The system is capable of applying OCR to scanned files. This functionality ensures that any text within scanned documents is processed.

