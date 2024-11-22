% Import necessary libraries
:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/json)).
:- use_module(library(csv)).
:- use_module(library(http/html_write)).

% Define the root handler
:- http_handler(root(.), root_handler, []).
:- http_handler('/eligibility', eligibility_handler, []).
:- http_handler('/exam_permission', exam_permission_handler, []).

% Root handler for initial request
root_handler(_Request) :-
    reply_html(
        [title('Welcome')],
        '<html><body><h1>Welcome to the Student Eligibility API!</h1></body></html>'
    ).

% Eligibility handler
eligibility_handler(Request) :-
    http_parameters(Request, [student_id(StudentID, [])]),
    (   eligible_for_scholarship(StudentID)
    ->  reply_json(_{status: 'eligible_for_scholarship'})
    ;   reply_json(_{status: 'not_eligible_for_scholarship'})
    ).

% Exam permission handler
exam_permission_handler(Request) :-
    http_parameters(Request, [student_id(StudentID, [])]),
    (   permitted_for_exam(StudentID)
    ->  reply_json(_{status: 'permitted_for_exam'})
    ;   reply_json(_{status: 'not_permitted_for_exam'})
    ).

% Load data from CSV file and assert it as facts
load_data :-
    retractall(student(_, _, _, _)),  % Clear existing facts
    csv_read_file('data.csv', Rows, [functor(student)]),
    assert_students(Rows).

% Helper predicate to assert student facts from CSV
assert_students([]).
assert_students([student(StudentID, Name, Attendance, CGPA) | T]) :-
    assertz(student(StudentID, Name, Attendance, CGPA)),
    assert_students(T).

% Scholarship eligibility rule
eligible_for_scholarship(Student_ID) :-
    student(Student_ID, _, Attendance, CGPA),
    Attendance >= 75,
    CGPA >= 9.0.

% Exam permission rule
permitted_for_exam(Student_ID) :-
    student(Student_ID, _, Attendance, _),
    Attendance >= 75.

% Start the server
start_server :-
    load_data,  % Load data from CSV file
    http_server(http_dispatch, [port(8000)]).  % Start the server on port 8000
