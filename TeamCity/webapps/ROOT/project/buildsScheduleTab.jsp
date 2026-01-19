<%@ page import="java.util.Date" %>
<%@ page import="jetbrains.buildServer.util.Dates" %>
<%@include file="/include-internal.jsp" %>

<jsp:useBean id="bean" scope="request" type="jetbrains.buildServer.controllers.project.schedule.BuildsScheduleBean"/>
<jsp:useBean id="form" scope="request" type="jetbrains.buildServer.controllers.project.schedule.BuildsScheduleForm"/>
<jsp:useBean id="projects" scope="request" type="java.util.Collection<jetbrains.buildServer.web.util.ProjectHierarchyBean>"/>
<jsp:useBean id="project" type="jetbrains.buildServer.serverSide.SProject" scope="request"/>

<%
  final Date now = Dates.now();
  request.setAttribute("now", now);
  request.setAttribute("nowTime", now.getTime());
  request.setAttribute("nowDate", Dates.truncateTime(now));
%>

<c:set var="timeTableChunks" value="${bean.timetableChunks}"/>
<c:set var="triggerInfos" value="${bean.triggers}"/>
<c:url var="controllerUrl" value="/buildSchedule.html"/>

<div class="section noMargin">
  <h2 class="noBorder">Builds Schedule</h2>
  <bs:smallNote>Below you can observe all builds schedules for a specific date.</bs:smallNote>

  <div class="actionBar clearfix">
    <%@ include file="_buildsScheduleForm.jspf" %>
  </div>

  <div class="error" id="error_scheduleDate" style="margin-left:0; white-space:nowrap;"></div>

  <script type="text/javascript">
    BS.BuildsSchedule.initDatePicker();
  </script>

  <%--@elvariable id="pageUrl" type="java.lang.String"--%>
  <bs:refreshable containerId="buildsScheduleContainer" pageUrl="${pageUrl}">
    <script type="text/javascript">
      BS.BuildsSchedule.adjustUpcoming(${form.scheduleDateAsDate ne nowDate});
    </script>
    <p>
      &nbsp;
      <span class="buildsSchedulePermalink">
      <bs:buildsScheduleLink
          showOnlyUpcoming="${form.showOnlyUpcoming}"
          scheduleDate="${form.scheduleDate}"
          showDisabled="${form.showDisabled}"
          showPaused="${form.showPaused}"
          hideOnlyPending="${form.hideOnlyPending}"
          projectId="${project.externalId}"
          filterProjectId="${form.filterProjectId}">Permalink</bs:buildsScheduleLink>
      </span>
    </p>

    <div>
      <c:choose>
        <c:when test="${not empty timeTableChunks}">
          <c:forEach var="chunk" items="${timeTableChunks}">
            <l:tableWithHighlighting highlightImmediately="true" id="buildsScheduleTable" className="parametersTable buildsScheduleTable">
              <thead>
              <tr>
                <th class="server-time">Server Time (<bs:formatDate pattern="Z" value="${now}"/>)</th>
                <th>Build Configuration and Pipelines</th>
                <th colspan="2" class="trigger">Trigger</th>
              </tr>
              </thead>
              <tbody>
              <c:forEach var="tableRow" items="${chunk.value}">
                <c:set var="triggerInfo" value="${triggerInfos[tableRow.triggerDescriptorId]}"/>
                <c:set var="canEdit" value="${triggerInfo.editable and triggerInfo.owner != null}"/>
                <c:set var="textStyleClass">
                  <c:if test="${tableRow.date.time < nowTime}"> pastEvent </c:if>
                </c:set>
                <c:set var="fontStyleClass">
                  <c:if test="${not triggerInfo.enabled}"> disabled </c:if>
                </c:set>
                <c:set var="paused">
                  <c:choose>
                    <c:when test="${not triggerInfo.inherited}">
                      <%--@elvariable id="owner" type="jetbrains.buildServer.serverSide.SBuildType"--%>
                      <c:set var="owner" value="${triggerInfo.owner}"/>
                      <c:if test="${triggerInfo.owner != null and owner.paused}">${true}</c:if>
                    </c:when>
                  </c:choose>
                </c:set>

                <c:choose>
                  <c:when test="${canEdit}">
                    <c:set var="onclickUrl">
                      <c:choose>
                        <c:when test="${not empty triggerInfo.pipeline}">
                          <admin:pipelineLink
                              pipelineId="${triggerInfo.pipeline.externalId}"
                              edit="true"
                              withoutLink="true"/>
                        </c:when>
                        <c:when test="${triggerInfo.inherited && !triggerInfo.overridden}">
                          <admin:editTemplateTriggerLink
                              template="${triggerInfo.owner}"
                              triggerId="${triggerInfo.triggerId}"
                              withoutLink="true"/>
                        </c:when>
                        <c:otherwise>
                          <admin:editBuildTypeTriggerLink
                              buildType="${triggerInfo.owner}"
                              triggerId="${triggerInfo.triggerId}"
                              withoutLink="true"/>
                        </c:otherwise>
                      </c:choose>
                    </c:set>
                    <c:set var="onclick">BS.openUrl(event, '${onclickUrl}');</c:set>
                    <c:set var="highlight" value="highlight"/>
                    <c:set var="editLink">
                      <a href="${onclickUrl}">Edit</a>
                    </c:set>
                  </c:when>
                  <c:otherwise>
                    <c:set var="onclick" value=" "/>
                    <c:set var="highlight" value=" "/>
                    <c:set var="editLink">
                <span class="noEdit">
                  cannot be edited
                </span>
                    </c:set>
                  </c:otherwise>
                </c:choose>
                <tr data-projectid="${tableRow.buildType.project.externalId}">
                  <td class="${highlight} ${textStyleClass}" onclick="${onclick}"><bs:formatDate pattern="HH:mm" value="${tableRow.date}"/></td>
                  <td class="${highlight}" onclick="${onclick}">
                    <c:choose>
                      <c:when test="${not empty triggerInfo.pipeline}">
                        <admin:pipelineLink pipelineId="${triggerInfo.pipeline.externalId}">
                          <bs:out value="${triggerInfo.pipeline.fullName}"/>
                        </admin:pipelineLink>
                      </c:when>
                      <c:otherwise>
                        <bs:buildTypeLink buildType="${tableRow.buildType}">
                          <bs:out value="${tableRow.buildType.fullName}"/>
                        </bs:buildTypeLink>
                      </c:otherwise>
                    </c:choose>
                    <c:if test="${paused}"><c:out value=" (paused) "/></c:if>
                  </td>
                  <td class="${highlight} ${textStyleClass} ${fontStyleClass} beforeActions" onclick="${onclick}"><bs:out
                      value="${triggerInfo.description}"/><bs:out value="${triggerInfo.inherited ? triggerInfo.overridden ? ' (inherited, overridden)' : ' (inherited)' : ''}"/><bs:out
                      value="${triggerInfo.enabled ? '' : ' (disabled)'}"/></td>
                  <td class="edit ${highlight}" onclick="${onclick}">${editLink}</td>
                </tr>
              </c:forEach>
              </tbody>
            </l:tableWithHighlighting>
            <br/>
          </c:forEach>
        </c:when>
        <c:otherwise>
          There are no builds scheduled.
        </c:otherwise>
      </c:choose>
    </div>
  </bs:refreshable>
</div>
