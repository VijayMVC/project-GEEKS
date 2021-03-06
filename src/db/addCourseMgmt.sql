-- addCourseMgmt.sql

-- Bruno DaSilva, Cristian Fitzgerald, Eliot Griffin, Kenneth Kozlowski
-- CS298-01 Spring 2019, Team GEEKS

----------------------------------------------------------------------------------

-- Function to add a course / add a row to the course table
-- parameters: Num (VARCHAR)  -- i.e "CS/MAT165"
--             newTitle (VARCHAR) -- i.e "Discrete Math"
--             Credits (INT) -- i.e "4"

CREATE OR REPLACE FUNCTION insertCourse(Num VARCHAR, newTitle VARCHAR, Credits INT)
RETURNS VOID AS
$$
BEGIN
    -- check if course exists
    -- and throw exception if exists already

    IF courseExists(Num,newTitle,NULL) IS true

    THEN
        RAISE EXCEPTION 'Course already exists';
    END IF;

    -- insert course
    INSERT INTO Gradebook.Course VALUES (Num, newTitle, Credits);

END
$$
LANGUAGE plpgsql;


-- Function to remove a course / remove a row in the course table
-- parameters: Num (VARCHAR) -- i.e "CS/MAT165"
--             oldTitle (VARCHAR) -- i.e "Discrete Math"

CREATE OR REPLACE FUNCTION removeCourse(Num VARCHAR, oldTitle VARCHAR)
RETURNS VOID AS

$$
BEGIN
   -- Check if course exists
   -- throw exception otherwise
   IF courseExists(Num, oldTitle, NULL) IS false
   THEN 
      RAISE EXCEPTION 'Course does not exist';
   END IF;

   -- remove course
   DELETE FROM Gradebook.Course WHERE Course.Number = Num 
                                AND Course.Title = oldTitle;

END
$$
LANGUAGE plpgsql;


-- Function to modify a course / update a row in the course table
-- parameters: currentNum (VARCHAR) -- Num of row to update
--             currentTitle (VARCHAR) -- Title of row to update
--             modNum (VARCHAR) -- possible new Num for that row
--             modTitle (VARCHAR) -- possiuble new Title for that row
--             modCredits (INT) -- possible new Title for that row

CREATE OR REPLACE FUNCTION modifyCourse(currentNum VARCHAR, currentTitle VARCHAR,
                           modNum VARCHAR, modTitle VARCHAR, modCredits INT)
RETURNS VOID AS
$$
BEGIN
   -- Make sure course wanting to be modified exists
   -- throw exception otherwise
   IF courseExists(currentNum, currentTitle,NULL) IS false
   THEN 
      RAISE EXCEPTION 'Course does not exist';
   END IF;

   -- Make sure that wanted modifications do not conflict with current Courses
   -- throw exception otherwise
   IF courseExists(modNum,modTitle,modCredits) IS true
   THEN
      RAISE EXCEPTION 'Modifications conflict with an already existing Course';
   END IF;
   
   -- update the row
   UPDATE Gradebook.Course 
      SET Number = modNum, 
          Title = modTitle, 
          Credits = modCredits
      WHERE Course.Title = currentTitle 
            AND Course.Number = currentNum;

END
$$
LANGUAGE plpgsql;


-- Function to test if a course exists in the DB
-- parameters: cNumber(VARCHAR) -- Course Number -- i.e "CS170"
--             cTitle (VARCHAR) -- Course title -- i.e "Intro to Programming"
--             cCredits (INT) -- Course credits -- i.e "4"
--
-- parameter cCredits may be NULL

CREATE OR REPLACE FUNCTION courseExists(cNumber VARCHAR, cTitle VARCHAR, cCredits INT)
RETURNS BOOL AS
$$
BEGIN
   -- evaluate if no credits are given (cCredits IS NULL)
   IF cCredits IS NULL
   THEN 
      IF EXISTS 
      (
         SELECT * FROM Gradebook.Course WHERE Course.Number = cNumber
                              AND Course.Title = cTitle
      )
      THEN
         RETURN true;
      END IF;
   END IF;
   
   -- evaluate if credits are given
   IF EXISTS
   (
      SELECT * FROM Gradebook.Course WHERE Course.Number = cNumber
                              AND Course.Title = cTitle
                              AND Course.Credits = cCredits
   )
   THEN 
      RETURN true;
   END IF;
   
   -- return false because course does not exist
   RETURN FALSE;

END
$$
LANGUAGE plpgsql;


-- Function to return a list of all current courses
-- parameters: none

CREATE OR REPLACE FUNCTION getCourses() 
RETURNS Table(outNumber VARCHAR,outTitle VARCHAR, outCredits INT) AS
$$
BEGIN

RETURN QUERY 
	SELECT Number,Title,Credits
	FROM Gradebook.Course;

END
$$
LANGUAGE plpgsql;


--Function to return a list of courses given course level and credit amount
-- parameters: number for level (i.e. 1 for 100 level, 0 for all level courses)
--             number of credits (i.e. 3, 0 for all credit amounts)
-- will throw exception if either parameter is less than 0

CREATE OR REPLACE FUNCTION getCourses(cLevel INT, cCredits INT) 
RETURNS Table(outNumber VARCHAR,outTitle VARCHAR, outCredits INT) AS
$$
BEGIN
-- check if parameters cLevel and cCredits are valid 
IF (cLevel < 0 OR cCredits < 0)
THEN
   THROW EXCEPTION "Invalid paramaters - cannot be < 0";
END IF;

-- return if cLevel is specified (greater than 0)
IF (cLevel > 0)
THEN

   -- return if both cLevel and cCredits are specified
   IF (cCredits > 0)
   THEN
      RETURN QUERY 
         SELECT Number,Title,Credits
         FROM Gradebook.Course
         WHERE Number LIKE CONCAT('%',cLevel,'__','%')
               AND Credits = cCredits;
   ELSE
   -- return if only cLevel specified - cCredits = 0
      RETURN QUERY
      SELECT Number,Title,Credits
         FROM Gradebook.Course
         WHERE Number LIKE CONCAT('%',cLevel,'__','%');
   END IF;

-- return if only cCredits is specified - cLevel is 0
ELSIF (cCredits > 0)
   THEN
      RETURN QUERY 
         SELECT Number,Title,Credits
         FROM Gradebook.Course
         WHERE Credits = cCredits;

ELSE
-- neither are specified - both parameters are 0
-- return all courses
   RETURN QUERY 
      SELECT Number,Title,Credits
      FROM Gradebook.Course;

END IF;

END
$$
LANGUAGE plpgsql;
