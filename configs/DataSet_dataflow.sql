create table CreditScore
(
    Credit_ID int,
    Card_Type nvarchar(50),
    Credit_Name nvarchar(50),
    Credit_score int
);
create table CreditScore_temp
(
    Credit_ID int,
    Card_Type nvarchar(50),
    Credit_Name nvarchar(50),
    Credit_score int
);

INSERT INTO CreditScore VALUES (1, 'visa',   'cloudfreak', 978);
INSERT INTO CreditScore VALUES (2, 'visa',   'rama',       1240);
INSERT INTO CreditScore VALUES (3, 'visa',   'krishna',    1140);
INSERT INTO CreditScore VALUES (4, 'visa',   'sai',        770);
INSERT INTO CreditScore VALUES (5, 'visa',   'sai',        770);
INSERT INTO CreditScore VALUES (6, 'visa',   'srinu',      1240);
INSERT INTO CreditScore VALUES (7, 'visa',   'srinu',      1240);
INSERT INTO CreditScore VALUES (8, 'visa',   'siva',       1140);
INSERT INTO CreditScore VALUES (9, 'visa',   'siva',       1140);

INSERT INTO CreditScore VALUES (1, 'master', 'cloudfreak', 978);
INSERT INTO CreditScore VALUES (2, 'master', 'rama',       770);
INSERT INTO CreditScore VALUES (3, 'master', 'krishna',    1140);
INSERT INTO CreditScore VALUES (4, 'master', 'sai',        1240);
INSERT INTO CreditScore VALUES (5, 'master', 'sai',        1240);
INSERT INTO CreditScore VALUES (6, 'master', 'srinu',      1240);
INSERT INTO CreditScore VALUES (7, 'master', 'srinu',      1240);
INSERT INTO CreditScore VALUES (8, 'master', 'siva',       1140);
INSERT INTO CreditScore VALUES (9, 'master', 'siva',       1140);

