import "@typespec/http";
import "@typespec/rest";
import "./common.tsp";

using TypeSpec.Http;
using TypeSpec.Rest;
using Ardtire.Common;

namespace Ardtire.Members;

enum MemberTier {
  ASSOCIATE_MEMBER,
  FULL_MEMBER,
}

enum MemberStanding {
  PENDING,
  ACTIVE,
  SUSPENDED,
  EXPELLED,
}

/**
 * A registered member of the Ardtire Society.
 */
model Member {
  @visibility("read") id: string;
  displayName: string;
  tier: MemberTier;
  standing: MemberStanding;
  ...Timestamps;
}

model CreateMemberInput {
  displayName: string;
  tier: MemberTier;
}

model UpdateMemberStandingInput {
  standing: MemberStanding;
  reason: string;
}

@route("/members")
@tag("members")
interface MemberEndpoints {
  /**
   * List all members (paginated).
   * Requires Officer role or higher.
   */
  @get
  @summary("List members")
  list(...PaginationQuery): {
    @statusCode statusCode: 200;
    @body body: PaginatedResponse<Member>;
  };

  /**
   * Get a single member by ID.
   */
  @get
  @route("{id}")
  @summary("Get member")
  get(@path id: string):
    | {
        @statusCode statusCode: 200;
        @body body: Member;
      }
    | {
        @statusCode statusCode: 404;
        @body body: ErrorResponse;
      };

  /**
   * Register a new member.
   */
  @post
  @summary("Create member")
  create(@body body: CreateMemberInput): {
    @statusCode statusCode: 201;
    @body body: Member;
  };

  /**
   * Update a member's standing (suspend, reinstate, or expel).
   * Requires Officer role or higher. Audit-logged.
   */
  @patch
  @route("{id}/standing")
  @summary("Update member standing")
  updateStanding(
    @path id: string,
    @body body: UpdateMemberStandingInput,
  ):
    | {
        @statusCode statusCode: 200;
        @body body: Member;
      }
    | {
        @statusCode statusCode: 404;
        @body body: ErrorResponse;
      }
    | {
        @statusCode statusCode: 422;
        @body body: ErrorResponse;
      };
}
