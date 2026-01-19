<%@ taglib prefix="form" uri="http://www.springframework.org/tags/form" %>
<%@ page import="java.util.Date" %>
<%@ include file="/include-internal.jsp" %>
<style type="text/css">
  td.buildsCount {
    width: 5em;
    text-align: right;
  }

  th.buildsCount {
    width: 5em;
  }

  table#deletedBuildTypesTable th {
    width: auto;
  }
</style>
<script type="application/javascript">
  BS.AttachBuildHistory = {
    confirmMessage: ${confirmMessage},

    attach: function() {
      if (!this.confirmMessage || confirm(this.confirmMessage)) {
        $j('#attachBuildHistoryProgress').show();
        $j('#attachBuildHistorySubmit').prop("disabled", true);
        var deletedBuildTypeId = $j('input[name=deletedBuildTypeId]:checked').val();
        BS.ajaxRequest(BS.AdminActions.url, {
          parameters: "attachBuildHistory=true&targetBuildTypeId=${buildType.externalId}&deletedBuildTypeId=" + deletedBuildTypeId,
          onComplete: function(transport) {
            var hasError = BS.XMLResponse.processErrors(transport.responseXML, {
              onAssignInternalIdError: function (elem) {
                $j('#assignInternalIdError').html(fixErrorMessage(elem.firstChild.nodeValue));
              }
            });
            $j('#attachBuildHistoryProgress').hide();
            $j('#attachBuildHistorySubmit').prop("disabled", false);
            if (!hasError) {
              BS.reload(true);
            }
          }
        });
      }
      return false;
    }
  };
</script>

<bs:messages key="buildHistoryAttached"/>

<div>
  <h3 style="display: inline">Target build configuration</h3> <bs:buildTypeLinkFull buildType="${buildType}"/>
  <span class="error" style="margin-left: 0" id="assignInternalIdError"></span>
</div>

<br/>
<h3>Deleted build configurations</h3>
<c:choose>
  <c:when test="${empty deleted}">
    <div style="margin-left: 1em;">
      No deleted build configurations found
    </div>
  </c:when>
  <c:otherwise>
    <table class="runnerFormTable" id="deletedBuildTypesTable">
      <tr>
        <th colspan="2">Id</th>
        <th>UUID</th>
        <th>Deleted</th>
        <th class="buildsCount">Last Build</th>
        <th class="buildsCount">#Builds</th>
      </tr>
      <c:forEach items="${deleted}" var="deletedBuildType">
        <c:url value="/orphanBuild.html?buildId=${deletedBuildType.lastBuildId}" var="lastBuildUrl"/>
        <tr>
          <td><input type="radio" name="deletedBuildTypeId" value="${deletedBuildType.externalId}"/></td>
          <td><c:out value="${deletedBuildType.externalId}"/></td>
          <td><c:out value="${deletedBuildType.uuid}"/></td>
          <td><bs:date value="${deletedBuildType.deleteDate}"/></td>
          <td class="buildsCount"><a href="${lastBuildUrl}">#<c:out value="${deletedBuildType.lastBuildNumber}"/></a></td>
          <td class="buildsCount"><c:out value="${deletedBuildType.buildsCount}"/></td>
        </tr>
      </c:forEach>
    </table>

    <div class="popupSaveButtonsBlock">
      <forms:submit id="attachBuildHistorySubmit" label="Attach" onclick="BS.AttachBuildHistory.attach();"/>
      <forms:saving id="attachBuildHistoryProgress"/>
    </div>
  </c:otherwise>
</c:choose>
