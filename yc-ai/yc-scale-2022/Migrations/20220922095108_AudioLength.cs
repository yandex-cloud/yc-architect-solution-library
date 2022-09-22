using Microsoft.EntityFrameworkCore.Migrations;

namespace yc_scale_2022.Migrations
{
    public partial class AudioLength : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_asr_recognition_SessionUuid_SessionUuidSpeechKitSessionId",
                table: "asr_recognition");

            migrationBuilder.DropPrimaryKey(
                name: "PK_SessionUuid",
                table: "SessionUuid");

            migrationBuilder.RenameTable(
                name: "SessionUuid",
                newName: "asr_speechkit_session_ids");

            migrationBuilder.AddColumn<double>(
                name: "AudioLen",
                table: "asr_recognition",
                nullable: true);

            migrationBuilder.AddPrimaryKey(
                name: "PK_asr_speechkit_session_ids",
                table: "asr_speechkit_session_ids",
                column: "SpeechKitSessionId");

            migrationBuilder.AddForeignKey(
                name: "FK_asr_recognition_asr_speechkit_session_ids_SessionUuidSpeech~",
                table: "asr_recognition",
                column: "SessionUuidSpeechKitSessionId",
                principalTable: "asr_speechkit_session_ids",
                principalColumn: "SpeechKitSessionId",
                onDelete: ReferentialAction.Restrict);
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_asr_recognition_asr_speechkit_session_ids_SessionUuidSpeech~",
                table: "asr_recognition");

            migrationBuilder.DropPrimaryKey(
                name: "PK_asr_speechkit_session_ids",
                table: "asr_speechkit_session_ids");

            migrationBuilder.DropColumn(
                name: "AudioLen",
                table: "asr_recognition");

            migrationBuilder.RenameTable(
                name: "asr_speechkit_session_ids",
                newName: "SessionUuid");

            migrationBuilder.AddPrimaryKey(
                name: "PK_SessionUuid",
                table: "SessionUuid",
                column: "SpeechKitSessionId");

            migrationBuilder.AddForeignKey(
                name: "FK_asr_recognition_SessionUuid_SessionUuidSpeechKitSessionId",
                table: "asr_recognition",
                column: "SessionUuidSpeechKitSessionId",
                principalTable: "SessionUuid",
                principalColumn: "SpeechKitSessionId",
                onDelete: ReferentialAction.Restrict);
        }
    }
}
