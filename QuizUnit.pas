unit QuizUnit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls, Vcl.Grids,
  Vcl.ExtCtrls, AdminUnit;

type
  TFormQuiz = class(TForm)
    PageControl1: TPageControl;
    LoginPage: TTabSheet;
    QuizPage: TTabSheet;
    ResultPage: TTabSheet;
    EditUserName: TEdit;
    BtnStart: TButton;
    Label1: TLabel;
    LabelQuestionNum: TLabel;
    LabelPackageName: TLabel;
    Memo1: TMemo;
    rbAnswer1: TRadioButton;
    rbAnswer2: TRadioButton;
    rbAnswer3: TRadioButton;
    rbAnswer4: TRadioButton;
    BtnNext: TButton;
    StringGrid1: TStringGrid;
    Label4: TLabel;
    Timer1: TTimer;
    LabelTimer: TLabel;
    OpenDialog1: TOpenDialog;
    procedure Timer1Timer(Sender: TObject);
    procedure BtnStartClick(Sender: TObject);
    procedure ShowQuestion(Idx: Integer);
    procedure BtnNextClick(Sender: TObject);
    procedure SaveResult;
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
    SecondsPassed: Integer;
  public
    { Public declarations }
    procedure ShowFinalResults;
  end;

var
  FormQuiz: TFormQuiz;
  UserQuestions: array of TQuestion; // Массив для вопросов
  CurrentFilePath: string;           // Имя выбранного пакета
  Score: Integer;                    // Счетчик правильных ответов
  CurrentQ: Integer;                 // Номер текущего вопроса
  SecondsPassed: Integer;            // Прошло времени

implementation

{$R *.dfm}

procedure TFormQuiz.ShowQuestion(Idx: Integer);
begin

  LabelPackageName.Caption := 'Вы проходите пакет вопросов: ' + ExtractFileName(CurrentFilePath);
  LabelQuestionNum.Caption := 'Номер вопроса: ' + IntToStr(Idx + 1) + ' из ' + IntToStr(Length(UserQuestions));

  // Текст вопроса
  Memo1.Text := string(UserQuestions[Idx].Text);

  // Варианты ответов на RadioButton-ы
  rbAnswer1.Caption := string(UserQuestions[Idx].Answers[0]);
  rbAnswer2.Caption := string(UserQuestions[Idx].Answers[1]);
  rbAnswer3.Caption := string(UserQuestions[Idx].Answers[2]);
  rbAnswer4.Caption := string(UserQuestions[Idx].Answers[3]);

  // Сброс выбранных radiobutton
  rbAnswer1.Checked := False;
  rbAnswer2.Checked := False;
  rbAnswer3.Checked := False;
  rbAnswer4.Checked := False;

  // Если вопрос последний, меняется текст на кнопке "Далее"
  if Idx = High(UserQuestions) then
    BtnNext.Caption := 'Завершить'
  else
    BtnNext.Caption := 'Далее';
end;

procedure TFormQuiz.SaveResult;
var
  ResFile: TextFile;
  ResLine: string;
begin
  AssignFile(ResFile, 'results.csv');
  // Если файла нет - создается, если есть - открывается для добавления
  if FileExists('results.csv') then Append(ResFile) else Rewrite(ResFile);

  try
    // Формируется строка: Имя;Баллы;Пакет;Время;Дата
    ResLine := Format('%s;%d;%s;%s;%s', [
      EditUserName.Text,
      Score,
      ExtractFileName(CurrentFilePath),
      LabelTimer.Caption,
      DateToStr(Now)
    ]);
    Writeln(ResFile, ResLine);
  finally
    CloseFile(ResFile);
  end;
end;

procedure TFormQuiz.ShowFinalResults;
var
  ResFile: TextFile;
  Line: string;
  Row: Integer;
  SList: TStringList;
begin
  PageControl1.ActivePageIndex := 2; // Переход на вкладку результатов

  // Заголовки таблицы
  StringGrid1.Cells[0, 0] := 'Имя';
  StringGrid1.Cells[1, 0] := 'Баллы';
  StringGrid1.Cells[2, 0] := 'Пакет';
  StringGrid1.Cells[3, 0] := 'Время';
  StringGrid1.Cells[4, 0] := 'Дата';

  AssignFile(ResFile, 'results.csv');
  Reset(ResFile);

  Row := 1;
  SList := TStringList.Create;
  try
    SList.Delimiter := ';';
    SList.StrictDelimiter := True; // Чтобы пробелы не считались разделителями

    while not Eof(ResFile) do
    begin
      Readln(ResFile, Line);
      SList.DelimitedText := Line;

      if SList.Count >= 5 then
      begin
        StringGrid1.RowCount := Row + 1; // Увеличение количества строк в таблице
        StringGrid1.Cells[0, Row] := SList[0];
        StringGrid1.Cells[1, Row] := SList[1];
        StringGrid1.Cells[2, Row] := SList[2];
        StringGrid1.Cells[3, Row] := SList[3];
        StringGrid1.Cells[4, Row] := SList[4];
        Inc(Row);
      end;
    end;
  finally
    SList.Free;
    CloseFile(ResFile);
  end;
end;

procedure TFormQuiz.BtnNextClick(Sender: TObject);
var
  SelectedAnswer: Integer;
begin
  // Проверка на выбранный ответ
  SelectedAnswer := -1;
  if rbAnswer1.Checked then SelectedAnswer := 0
  else if rbAnswer2.Checked then SelectedAnswer := 1
  else if rbAnswer3.Checked then SelectedAnswer := 2
  else if rbAnswer4.Checked then SelectedAnswer := 3;

  if SelectedAnswer = -1 then
  begin
    ShowMessage('Выберите вариант ответа!');
    Exit;
  end;

  // Проверка правильности
  if SelectedAnswer = UserQuestions[CurrentQ].CorrectIndex then
    Inc(Score);

  // Переход к следующему вопросу или завершение
  if CurrentQ < High(UserQuestions) then
  begin
    Inc(CurrentQ);
    ShowQuestion(CurrentQ);
  end
  else
  begin
    // Конец теста
    Timer1.Enabled := False; // Остановка таймера
    ShowMessage('Викторина завершена!');
    SaveResult; // Сохранение в CSV
    ShowFinalResults; // Переход на 3-ю вкладку
  end;
end;

procedure TFormQuiz.BtnStartClick(Sender: TObject);
var
  TempQ: TQuestion;
begin
  // Проверка ввода имени
  if (Trim(EditUserName.Text) = '') or (EditUserName.Text = 'Ваше имя') then
  begin
    ShowMessage('Пожалуйста, введите ваше имя!');
    Exit;
  end;

  // Выбор пакета вопросов
  if OpenDialog1.Execute then
  begin
    CurrentFilePath := OpenDialog1.FileName;

    // Алгоритм загрузки вопросов
    AssignFile(F, CurrentFilePath);
    Reset(F);
    try
      SetLength(UserQuestions, 0);
      while not Eof(F) do
      begin
        Read(F, TempQ);
        SetLength(UserQuestions, Length(UserQuestions) + 1);
        UserQuestions[High(UserQuestions)] := TempQ;
      end;
    finally
      CloseFile(F);
    end;

    // Проверка на пустой файл
    if Length(UserQuestions) = 0 then
    begin
      ShowMessage('В выбранном пакете нет вопросов!');
      Exit;
    end;

    // Подготовка к тесту
    Score := 0;
    CurrentQ := 0;
    SecondsPassed := 0;

    // Вывод названия пакет на форму
    LabelPackageName.Caption := 'Пакет: ' + ExtractFileName(CurrentFilePath);

    // Переход на вкладку теста
    PageControl1.ActivePageIndex := 1;

    // Запуск таймера и отображение первого вопроса
    Timer1.Enabled := True;
    ShowQuestion(0);
  end;
end;

procedure TFormQuiz.FormCreate(Sender: TObject);
begin
  // Выбор первой вкладки при запуске
  PageControl1.ActivePageIndex := 0;

  // Заголовки таблицы
  StringGrid1.Cells[0, 0] := 'Имя';
  StringGrid1.Cells[1, 0] := 'Баллы';
  StringGrid1.Cells[2, 0] := 'Пакет';
  StringGrid1.Cells[3, 0] := 'Время';
  StringGrid1.Cells[4, 0] := 'Дата';
end;

procedure TFormQuiz.Timer1Timer(Sender: TObject);
begin
  Inc(SecondsPassed); // Увечение счетчика таймера на 1
  // Вывод в формате 00:00
  LabelTimer.Caption := Format('%.2d:%.2d', [SecondsPassed div 60, SecondsPassed mod 60]);
end;

end.
