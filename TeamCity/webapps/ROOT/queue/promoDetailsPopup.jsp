<%@include file="/include-internal.jsp"%>
<jsp:useBean id="promotionDetailsBean" scope="request" type="jetbrains.buildServer.controllers.BuildPromotionDetailsBean"/>
<c:set var="promotion" value="${promotionDetailsBean.promotion}"/>
<c:set var="triggeredBy" value="${promotionDetailsBean.triggeredBy}"/>
<div class="summaryContainer">
<c:if test="${not empty triggeredBy}">
<div class="popupHeader">Added to queue on <bs:date value="${triggeredBy.triggeredDate}"/></div>
</c:if>
<c:if test="${empty param.hideChanges}">
<div class="header">Changes</div>
  <ul>
    <li>
      <c:set var="changesBean" value="${promotionDetailsBean.changesBean}"/>
      <c:set var="numPersonal" value="${fn:length(promotion.personalChanges)}"/>
      <c:choose>
        <c:when test="${(not promotion.personal or numPersonal == 0) and not promotionDetailsBean.changesCollected}">
          Changes are not yet collected for this build.
        </c:when>
        <c:when test="${promotion.personal and not promotionDetailsBean.changesCollected}">
          This build will include <strong>${numPersonal}</strong> personal change<bs:s val="${numPersonal}"/>, other changes are not yet collected.
        </c:when>
        <c:when test="${promotionDetailsBean.changesCollected and changesBean.total > 0}">
          Changes are collected, this build will include <strong>${changesBean.total}</strong> change<bs:s val="${changesBean.total}"/><c:if test="${changesBean.limit > 0 and changesBean.total > changesBean.limit}"> (only <strong>${changesBean.limit}</strong> are shown)</c:if>:
        </c:when>
        <c:when test="${promotionDetailsBean.changesCollected and changesBean.total == 0}">
          Changes are collected, there are no changes found.
        </c:when>
      </c:choose>
      <c:if test="${changesBean.total > 0}">
        <table class="changesTable">
          <c:forEach items="${changesBean.changes}" var="userChanges">
            <c:forEach items="${userChanges.changes}" var="change">
            <tr>
              <td class="changeUsername">
                <c:if test="${change.relatedVcsChange.personal}"><bs:personalChangesIcon1 mod="${change.relatedVcsChange}"/></c:if>
                <bs:changeCommitters modification="${change.relatedVcsChange}"/>
              </td>
              <td class="changeComment">
                <bs:subrepoIcon modification="${change.relatedVcsChange}"/>
                <c:choose>
                  <c:when test="${fn:length(change.description) > 0}"><bs:out resolverContext="${promotion}" value="${change.description}"/></c:when>
                  <c:otherwise>No comment</c:otherwise>
                </c:choose>
              </td>
              <td class="chainChangesIcon">
                <c:if test="${changefn:isSnapshotDependencyModification(change)}">
                  <bs:snapDepChangeLink snapDepLink="${changefn:getSnapDepLink(change)}"/>
                </c:if>
              </td>
              <td class="changedFiles">
                <bs:changedFilesLink modification="${change.relatedVcsChange}" buildType="${changesBean.ownerBuildType}"/>
              </td>
            </tr>
            </c:forEach>
          </c:forEach>
        </table>
      </c:if>
     </li>
  </ul>
</c:if>
<c:set var="customizedParams" value="${promotionDetailsBean.customParameters}"/>
<c:set var="customizedConfParams" value="${customizedParams.overriddenConfigParametersList}"/>
<c:set var="customizedSystemProps" value="${customizedParams.overriddenSystemPropertiesList}"/>
<c:set var="customizedEnvVars" value="${customizedParams.overriddenEnvVariablesList}"/>
<c:if test="${(fn:length(customizedSystemProps) + fn:length(customizedEnvVars) + fn:length(customizedConfParams)) != 0}">
  <div class="header">Custom Parameters</div>
  <c:if test="${not empty customizedConfParams}">
    <div class="info"><strong>Configuration Parameters</strong></div>
    <table class="info" style="margin-left: 1em;">
      <c:forEach var="prop" items="${customizedConfParams}">
        <tr>
          <td><c:out value="${prop.name}"/></td>
          <td>=</td>
          <td><c:out value="${prop.value}"/></td>
        </tr>
      </c:forEach>
    </table>
  </c:if>
  <c:if test="${not empty customizedSystemProps}">
    <div class="info"><strong>System Properties</strong></div>
    <table class="info" style="margin-left: 1em;">
      <c:forEach var="prop" items="${customizedSystemProps}">
        <tr>
          <td><c:out value="${prop.name}"/></td>
          <td>=</td>
          <td><c:out value="${prop.value}"/></td>
        </tr>
      </c:forEach>
    </table>
  </c:if>
  <c:if test="${not empty customizedEnvVars}">
    <div class="info"><strong>Environment Variables</strong></div>
    <table class="info" style="margin-left: 1em;">
      <c:forEach var="env" items="${customizedEnvVars}">
        <tr>
          <td><c:out value="${env.name}"/></td>
          <td>=</td>
          <td><c:out value="${env.value}"/></td>
        </tr>
      </c:forEach>
    </table>
  </c:if>
</c:if>
<c:if test="${empty param.hideBuildComment}">
  <c:set var="comment" value="${promotion.buildComment}"/>
  <c:if test="${not empty comment}">
    <div class="header">Build comment</div>
    <div class="info"><strong><c:out value="${comment.user.descriptiveName}"/></strong>: <bs:out value="${comment.comment}"/></div>
  </c:if>
</c:if>
<c:if test="${promotionDetailsBean.promotion.partOfBuildChain}">
  <div class="header">Dependencies</div>
  <div class="info">This build is a part of a build chain.<bs:help file="Build+Chain" /></div>
  <c:choose>
    <c:when test="${promotionDetailsBean.allDependenciesInaccessible}">
      <div class="attentionComment"><bs:buildStatusIcon type="red-sign" className="warningIcon"/>You don't have access rights to see its other parts.</div>
    </c:when>
    <c:when test="${promotionDetailsBean.notAllDependenciesAccessible}">
      <div class="attentionComment"><bs:buildStatusIcon type="red-sign" className="warningIcon"/>You don't have access rights to see some of its parts.</div>
    </c:when>
  </c:choose>
  <ul>
    <c:forEach var="dependOn" items="${promotionDetailsBean.dependencies}">
      <li><bs:queueDependencyState dependency="${dependOn}"/></li>
    </c:forEach>
  </ul>
</c:if>
</div>
