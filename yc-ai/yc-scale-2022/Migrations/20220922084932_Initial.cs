using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

namespace yc_scale_2022.Migrations
{
    public partial class Initial : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "asr_sessions",
                columns: table => new
                {
                    AsrSessionId = table.Column<Guid>(nullable: false),
                    StartDate = table.Column<DateTime>(nullable: false),
                    TraceIdentifier = table.Column<string>(nullable: true),
                    UserAgent = table.Column<string>(type: "varchar(255)", nullable: true),
                    RemoteIpAddress = table.Column<string>(type: "varchar(32)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_asr_sessions", x => x.AsrSessionId);
                });

            migrationBuilder.CreateTable(
                name: "ml_inference",
                columns: table => new
                {
                    InferenceId = table.Column<int>(nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    RecognitionId = table.Column<Guid>(nullable: false),
                    NoEmotion = table.Column<double>(nullable: false),
                    Joy = table.Column<double>(nullable: false),
                    Sadness = table.Column<double>(nullable: false),
                    Surprise = table.Column<double>(nullable: false),
                    Fear = table.Column<double>(nullable: false),
                    Anger = table.Column<double>(nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ml_inference", x => x.InferenceId);
                });

            migrationBuilder.CreateTable(
                name: "SessionUuid",
                columns: table => new
                {
                    SpeechKitSessionId = table.Column<int>(nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    Uuid = table.Column<string>(nullable: true),
                    UserRequestId = table.Column<string>(nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SessionUuid", x => x.SpeechKitSessionId);
                });

            migrationBuilder.CreateTable(
                name: "asr_recognition",
                columns: table => new
                {
                    RecognitionId = table.Column<Guid>(nullable: false),
                    SessionId = table.Column<Guid>(nullable: false),
                    RecognitionDateTime = table.Column<DateTime>(nullable: false),
                    TrackerKey = table.Column<string>(type: "varchar(100)", nullable: true),
                    SessionUuidSpeechKitSessionId = table.Column<int>(nullable: true),
                    EventCase = table.Column<int>(nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_asr_recognition", x => x.RecognitionId);
                    table.ForeignKey(
                        name: "FK_asr_recognition_SessionUuid_SessionUuidSpeechKitSessionId",
                        column: x => x.SessionUuidSpeechKitSessionId,
                        principalTable: "SessionUuid",
                        principalColumn: "SpeechKitSessionId",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "asr_alternative",
                columns: table => new
                {
                    AlternativeId = table.Column<Guid>(nullable: false),
                    RecognitionId = table.Column<Guid>(nullable: false),
                    Text = table.Column<string>(nullable: true),
                    StartTimeMs = table.Column<int>(nullable: false),
                    EndTimeMs = table.Column<int>(nullable: false),
                    Confidence = table.Column<int>(nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_asr_alternative", x => x.AlternativeId);
                    table.ForeignKey(
                        name: "FK_asr_alternative_asr_recognition_AlternativeId",
                        column: x => x.AlternativeId,
                        principalTable: "asr_recognition",
                        principalColumn: "RecognitionId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "asr_word",
                columns: table => new
                {
                    WordId = table.Column<int>(nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    AlternativeId = table.Column<Guid>(nullable: false),
                    Text = table.Column<string>(nullable: true),
                    StartTimeMs = table.Column<int>(nullable: false),
                    EndTimeMs = table.Column<int>(nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_asr_word", x => x.WordId);
                    table.ForeignKey(
                        name: "FK_asr_word_asr_alternative_AlternativeId",
                        column: x => x.AlternativeId,
                        principalTable: "asr_alternative",
                        principalColumn: "AlternativeId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_asr_recognition_SessionUuidSpeechKitSessionId",
                table: "asr_recognition",
                column: "SessionUuidSpeechKitSessionId");

            migrationBuilder.CreateIndex(
                name: "IX_asr_word_AlternativeId",
                table: "asr_word",
                column: "AlternativeId");
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "asr_sessions");

            migrationBuilder.DropTable(
                name: "asr_word");

            migrationBuilder.DropTable(
                name: "ml_inference");

            migrationBuilder.DropTable(
                name: "asr_alternative");

            migrationBuilder.DropTable(
                name: "asr_recognition");

            migrationBuilder.DropTable(
                name: "SessionUuid");
        }
    }
}
