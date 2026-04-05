import "@typespec/http";
import "@typespec/rest";
import "./common.tsp";

using TypeSpec.Http;
using TypeSpec.Rest;
using Ardtire.Common;

namespace Ardtire.Governance;

enum ProposalStatus {
  DRAFT,
  SUBMITTED,
  UNDER_DELIBERATION,
  VOTING,
  RATIFICATION_PENDING,
  RATIFIED,
  REJECTED,
  WITHDRAWN,
}

enum VoteChoice {
  AYE,
  NAY,
  ABSTAIN,
}

/**
 * A formal governance proposal. Initiates the governance lifecycle.
 */
model Proposal {
  @visibility("read") id: string;
  title: string;
  summary: string;
  body: string;
  status: ProposalStatus;

  /** The ID of the rule version active at submission time. Immutable after submission. */
  @visibility("read") ruleVersionId: string;

  /** The member ID of the proposer. */
  @visibility("read") submitterId: string;

  deliberationOpensAt?: utcDateTime;
  deliberationClosesAt?: utcDateTime;
  votingOpensAt?: utcDateTime;
  votingClosesAt?: utcDateTime;

  ...Timestamps;
}

model SubmitProposalInput {
  title: string;
  summary: string;
  body: string;
}

model CastVoteInput {
  choice: VoteChoice;
}

model VoteRecord {
  @visibility("read") id: string;
  @visibility("read") proposalId: string;
  @visibility("read") voterId: string;
  choice: VoteChoice;
  @visibility("read") castAt: utcDateTime;
}

model VoteResult {
  @visibility("read") proposalId: string;
  ayeCount: int32;
  nayCount: int32;
  abstainCount: int32;
  totalEligible: int32;
  quorumMet: boolean;
  passed: boolean;
  @visibility("read") computedAt: utcDateTime;
}

@route("/governance/proposals")
@tag("proposals")
interface ProposalEndpoints {
  /**
   * List governance proposals (paginated).
   */
  @get
  @summary("List proposals")
  list(...PaginationQuery): {
    @statusCode statusCode: 200;
    @body body: PaginatedResponse<Proposal>;
  };

  /**
   * Get a single proposal by ID.
   */
  @get
  @route("{id}")
  @summary("Get proposal")
  get(@path id: string):
    | {
        @statusCode statusCode: 200;
        @body body: Proposal;
      }
    | {
        @statusCode statusCode: 404;
        @body body: ErrorResponse;
      };

  /**
   * Submit a new governance proposal.
   * Requires Full Member standing or Officer role.
   */
  @post
  @summary("Submit proposal")
  submit(@body body: SubmitProposalInput): {
    @statusCode statusCode: 201;
    @body body: Proposal;
  };

  /**
   * Cast a vote on a proposal.
   * The requesting member must be eligible (Full Member, ACTIVE standing,
   * enrolled before vote-open time). Each eligible member may vote exactly once.
   */
  @post
  @route("{id}/votes")
  @summary("Cast vote")
  castVote(
    @path id: string,
    @body body: CastVoteInput,
  ):
    | {
        @statusCode statusCode: 201;
        @body body: VoteRecord;
      }
    | {
        @statusCode statusCode: 404;
        @body body: ErrorResponse;
      }
    | {
        @statusCode statusCode: 409;
        @body body: ErrorResponse;
      }
    | {
        @statusCode statusCode: 422;
        @body body: ErrorResponse;
      };

  /**
   * Get the computed vote result for a proposal.
   * Only available after voting has closed.
   */
  @get
  @route("{id}/result")
  @summary("Get vote result")
  getResult(@path id: string):
    | {
        @statusCode statusCode: 200;
        @body body: VoteResult;
      }
    | {
        @statusCode statusCode: 404;
        @body body: ErrorResponse;
      }
    | {
        @statusCode statusCode: 409;
        @body body: ErrorResponse;
      };
}
