CREATE TYPE SEXO AS ENUM('M','F');
CREATE TYPE TURMA_SEMESTRE AS ENUM ('1','2');
CREATE TYPE TURMA_ESTADO AS ENUM ('ABERTA','CONCLUÍDA');
CREATE TYPE DIAS AS ENUM ('segunda', 'terça','quarta','quinta','sexta','sábado');


CREATE TABLE Professor(
	id_prof SERIAL PRIMARY KEY,
	nome_prof VARCHAR(30) NOT NULL,
	email VARCHAR(30) NOT NULL,
	grau_maximo_de_formacao VARCHAR(20) NOT NULL,
	sexo_professor SEXO NOT NULL,
	nascimento DATE NOT NULL
);

CREATE TABLE Reitor(
	id_reitor serial PRIMARY KEY,
	nome_reitor VARCHAR(30) NOT NULL,
	data_de_nascimento DATE NOT NULL,
	data_de_admissao DATE NOT NULL,
	id_professor INT NOT NULL,
	FOREIGN KEY(id_professor) REFERENCES Professor ON DELETE CASCADE
)INHERITS(Professor);

CREATE TABLE Campus(
	id_campus SERIAL PRIMARY KEY,
	nome_campus VARCHAR(10) NOT NULL,
	munincipio VARCHAR(20) NOT NULL,
	UNIQUE(nome_campus, munincipio)
);

CREATE TABLE Centro(
	id_centro SERIAL PRIMARY KEY,
	nome_centro VARCHAR(15) NOT NULL,
	diretor INT UNIQUE,
	FOREIGN KEY(diretor) REFERENCES Professor ON DELETE CASCADE,
	campus INT NOT NULL,
	FOREIGN KEY(campus) REFERENCES Campus ON DELETE CASCADE
);
	
CREATE TABLE Curso(
	id_curso SERIAL PRIMARY KEY,
	nome_curso VARCHAR(30) NOT NULL,
	carga_horaria INT NOT NULL,
	coordenador INT UNIQUE,
	FOREIGN KEY(coordenador) REFERENCES Professor ON DELETE CASCADE,
	centro INT,
	FOREIGN KEY(centro) REFERENCES Centro ON DELETE CASCADE
);

CREATE TABLE Bloco(
    id_bloco SERIAL PRIMARY KEY,
    nome_bloco VARCHAR(10),
    centro INT NOT NULL,
	FOREIGN KEY(centro) REFERENCES Centro ON DELETE CASCADE
);

CREATE TABLE Localizacao(
    id_local SERIAL PRIMARY KEY,
    nome_local VARCHAR(10) NOT NULL,
    bloco INT,
    FOREIGN KEY(bloco) REFERENCES Bloco ON DELETE CASCADE,
    lotacao INT NOT NULL,
    descricao TEXT,
    tipo_local VARCHAR(15) NOT NULL,
    CHECK (tipo_local = 'bloco' OR tipo_local = 'sala de aula'
           OR tipo_local = 'auditório' OR tipo_local = 'laboratório' or 
           tipo_local = 'biblioteca')
);

--trigger para saber se o bloco é nulo, caso seja lanço uma excecao

CREATE OR REPLACE FUNCTION isBlocoNulo_func() RETURNS TRIGGER AS $$
BEGIN
    IF (NEW.tipo_local = 'bloco')THEN
        IF NEW.bloco IS NOT NULL THEN
            RAISE EXCEPTION 'O registro bloco precisa ser nulo';
        END IF;
    ELSE 
        IF NEW.bloco IS NULL THEN
            RAISE EXCEPTION 'O registro não pode ser nulo';
        END IF;
    END IF;
    RETURN NEW;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER isBlocoNulo
before INSERT or UPDATE 
ON Localizacao
FOR EACH ROW
EXECUTE FUNCTION isBlocoNulo_func();

CREATE TABLE Avaliacoes_Disc(
	id_aval SERIAL PRIMARY KEY,
	primeira_aval INT NOT NULL,
	CHECK(primeira_aval >= 0 OR primeira_aval <= 10),
	segunda_aval INT,
	CHECK(segunda_aval >= 0 OR segunda_aval <= 10),
	terca_aval INT,
	CHECK(terca_aval >= 0 OR terca_aval <= 10),
	quarta_aval INT,
	CHECK(quarta_aval >= 0 OR quarta_aval <= 10),
	quinta_aval INT,
	CHECK(quinta_aval >= 0 OR quinta_aval <= 10),
	sexta_aval INT,
	CHECK(sexta_aval >= 0 OR sexta_aval <= 10)
);

CREATE TABLE Disciplina(
	id_disc SERIAL PRIMARY KEY,
	nome_disc VARCHAR(20) NOT NULL,
	ementa TEXT NOT NULL,
	carga_horaria INT NOT NULL,
	professor INT,
	FOREIGN KEY(professor) REFERENCES Professor ON DELETE CASCADE,
	CHECK(carga_horaria = 32 OR carga_horaria = 64 
		  OR carga_horaria = 96 OR carga_horaria = 128),
	avaliacoes INT NOT NULL,
	FOREIGN KEY(avaliacoes) REFERENCES Avaliacoes_Disc ON DELETE CASCADE
);

-- trigger para na hora de inserir, eu conto a qtd de vezes que o prof aparece

CREATE OR REPLACE FUNCTION num_disc_prof_func() RETURNS TRIGGER AS $$
DECLARE
	cont INTEGER;
BEGIN
	SELECT COUNT(id_disc) FROM Disciplina WHERE professor = NEW.professor INTO cont;
	IF (cont > 4) THEN
		RAISE EXCEPTION 'O Professor já atingiu o número máximo de disciplinas';
	END IF;
  	RETURN NULL;
END;
$$
LANGUAGE plpgsql;


CREATE TRIGGER num_disc_prof
AFTER INSERT OR UPDATE
ON Disciplina
FOR EACH ROW 
EXECUTE FUNCTION num_disc_prof_func();

CREATE TABLE Turma_Dias_Semana(
	id_tds SERIAL PRIMARY KEY,
	primeiro_dia DIAS NOT NULL,
	segundo_dia DIAS,
	terceiro_dia DIAS
);

CREATE TABLE Turma(
	id_turma SERIAL PRIMARY KEY,
	ano VARCHAR(4) NOT NULL,
	semestre TURMA_SEMESTRE NOT NULL,
	estado TURMA_ESTADO NOT NULL,
	disciplina INT NOT NULL,
	FOREIGN KEY(disciplina) REFERENCES Disciplina ON DELETE CASCADE,
	localizacao INT,
	FOREIGN KEY(localizacao) REFERENCES Localizacao ON DELETE CASCADE,
	dias_semana INT,
	FOREIGN KEY(dias_semana) REFERENCES Turma_Dias_Semana ON DELETE CASCADE,
	horario_inicio INT NOT NULL,
	CHECK(horario_inicio >= 8 AND horario_inicio <= 20),
	horario_fim INT NOT NULL,
	CHECK(horario_fim >= 10 AND horario_fim <= 22),
	vagas INT,
	CHECK(vagas > 0),
	qtd_matriculados INT DEFAULT 0,
	CHECK(qtd_matriculados <= vagas)
);

CREATE OR REPLACE FUNCTION adiciona_alunos_func() RETURNS TRIGGER AS $$
BEGIN
	IF (TG_OP = 'DELETE') THEN
		UPDATE Turma SET qtd_matriculados = qtd_matriculados - 1 WHERE id_turma = OLD.id_turma;
	ELSIF (TG_OP = 'INSERT') THEN
		UPDATE Turma SET qtd_matriculados = qtd_matriculados + 1 WHERE id_turma = NEW.id_turma;
	END IF;
	RETURN NULL;
END;
$$
LANGUAGE plpgsql;


CREATE TRIGGER adiciona_alunos
AFTER INSERT OR DELETE
ON Turma
FOR EACH ROW
EXECUTE FUNCTION adiciona_alunos_func();


CREATE TABLE Endereco_Aluno(
	id_endereco SERIAL PRIMARY KEY,
	rua VARCHAR(20) NOT NULL,
	numero_casa VARCHAR(6) NOT NULL,
	cep VARCHAR(9) NOT NULL,
	bairro VARCHAR(15) NOT NULL,
	cidade VARCHAR(20)NOT NULL,
	estado VARCHAR(2) NOT NULL,
	complemento VARCHAR(6)
);

CREATE TABLE Aluno(
	matricula SERIAL PRIMARY KEY,
	nome_aluno VARCHAR(30) NOT NULL,
	email_aluno VARCHAR(20) NOT NULL,
	data_de_nasc DATE NOT NULL,
	sexo_aluno SEXO NOT NULL,
	endereco INT NOT NULL,
	FOREIGN KEY(endereco) REFERENCES Endereco_Aluno ON DELETE CASCADE,
	curso_aluno INT NOT NULL,
	FOREIGN KEY(curso_aluno) REFERENCES Curso ON DElETE CASCADE,
	turmas INT,
	FOREIGN KEY(turmas) REFERENCES Turma ON DELETE CASCADE
);


INSERT INTO Professor VALUES(1,'Yuri Fernandes','yurifernandes@gmail.com','DOUTORADO','M','1999-01-08');
INSERT INTO Professor VALUES(2,'Wagner Ramos','waguin123@gmail.com','PÓS-DOUTORADO','M','2002-05-24');
INSERT INTO Professor VALUES(3,'Turgueniev Freitas','tutu78974@hotmail.com','GRADUADO','M','2000-05-30');
INSERT INTO Disciplina VALUES(default,'Matematica Finita','ablubleble',96,1);
INSERT INTO Disciplina VALUES(default,'Algebra Linear','ablubleble',96,1);
INSERT INTO Disciplina VALUES(default,'Programação Linear','ablubleble',96,1);
INSERT INTO Disciplina VALUES(default,'FUP','ablubleble',96,1);
INSERT INTO Disciplina VALUES(default,'Calculo de Prob','ablubleble',96,1);

truncate table localizacao;
truncate table Bloco;
truncate table centro;
truncate table campus;


INSERT INTO Campus VALUES (default, 'Pici', 'Fortaleza'); 
INSERT INTO Campus VALUES (default, 'Benfica', 'Fortaleza'); 
INSERT INTO Centro VALUES (default, 'Ciências', 2, 1); 
INSERT INTO Centro VALUES (default, 'Humanidades', 1, 2); 
INSERT INTO Bloco VALUES (default, '1024', 1); 
INSERT INTO Bloco VALUES (default, '789', 2); 
INSERT INTO Localizacao VALUES (default,'A',null, 41, 'ablubleble', 'bloco');
INSERT INTO Localizacao VALUES (default,'B',null, 42, 'ablubleble', 'biblioteca'); --vai dar erro pq bloco tá nulo
INSERT INTO Localizacao VALUES (default,'C',1, 43, 'ablubleble', 'sala de aula');
INSERT INTO Localizacao VALUES (default,'B',2, 42, 'ablubleble', 'biblioteca'); 
INSERT INTO Localizacao VALUES (default,'D',1, 42, 'ablubleble', 'bloco'); --vai dar erro pq bloco precisa ser nulo

select * FROM localizacao;
SELECT * FROM Campus;
SELECT * FROM Bloco;
SELECT * FROM Centro;
SELECT * FROM Professor;