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

Comprehensive Reading Functionality

1. **Book Organization**
   * The system shall enable users to convert books between various formats.
   * It shall allow users to edit metadata, perform full-text searches, group books into categories, and add tags for quick searches.
   * Users shall be able to define categories with conditions such as "Release date is after 1950" or "Contains fewer than 100 pages."
   * The system shall support defining categories using a query language or via a graphical interface by selecting values from a list.



### ---

### User management

1. The systems shall allow the user to create an account by providing the following information: username, email, password.
2. The system shall allow the user to login to the system in the following ways:
   1. Username and password pair.
   2. Email and password pair (interchangeable with method 1).
   3. Google account though single sign-on process.
3. The system shall allow the user to recover forgotten password by sending the recovery link to the email, if such is found.&#x20;

## Book Management System

### Features

#### Tagging System

* **Assign Tags**: Users can assign tags to a book, each consisting of a title and a color. A book can have between 0 to 10 unique tags, allowing for versatile categorization and easy retrieval.

#### Shelve Creation

* **Organize with Shelves**: Users can create custom shelves to group and organize available books according to preference, enhancing navigation and management of the library.

#### Optical Character Recognition (OCR)

* **Scanned Files**: The system is capable of applying OCR to scanned files. This functionality ensures that any text within scanned documents is processed, making it accessible and usable in our comprehensive search system.

#### Indexing and Full Text Search

* **Index Uploaded Content**: All uploaded book contents are indexed for efficient full text searching. This feature allows users to quickly locate specific phrases or content within a book file.
* **Search Criteria**: Users can search by the following attributes:
  * **Tags**: Find books based on user-defined tags.
  * **ISBN Number**: Use the International Standard Book Number for precise searching.
  * **Publication Date**: Locate books according to their publication timeline.
  * **Publisher**: Search for books from specific publishers.
  * **Author**: Identify books by entering the author's name.
  * **Title**: Quickly find books by searching for the title.

#### File Upload

* **Upload Books**: Users can upload book files directly from their device’s filesystem, seamlessly integrating personal or newly acquired books into the system for easy management and search functionality.



### Insights

1.  The system shall track time spent reading the book and pages read.System Features and Functionalities

    #### Filters for Statistics Display

    The system offers comprehensive filtering options to tailor the statistics display to specific needs. Users can choose to filter the statistics based on the following attributes:

    * **Time Frame Options:**
      * **Last Year**: View statistics for activities conducted in the previous calendar year.
      * **Last Month**: Focus on engagements recorded in the past month.
      * **Last Week**: Analyze the activities logged in the previous week.
      * **Custom Interval**: Define a specific start and end date to examine data within a chosen time frame.
      * **Time Interval**: Select from predefined intervals like the past 7 days, 30 days, or user-defined periods for a customized view.
    * **Book Selection Preferences:**
      * **Selected Books**: Narrow down the statistics to a specific selection of books.
      * **All Books**: Broaden the view to encompass all books within the user's library.

    #### Statistics and Metrics Available

    Once the filters are applied, the system allows users to delve into detailed analytics. Users can view and analyze the following statistics, either for all books or focusing solely on selected ones:

    * **Time Spent per Page**: Discover how much time on average is dedicated to each page, providing insights into reading pace.
    * **Pages Read**: Track the number of pages consumed over the selected period, giving a sense of reading volume.
    * **Books Read**: Obtain a count of books completed within the designated timeframe, reflecting reading accomplishments.
    * **Time Spent Reading**: Assess the total time invested in reading, providing an overview of engagement levels.

    These features enable users to gain in-depth insights and enhance their reading and learning experiences by understanding their behaviors and habits in detail.

