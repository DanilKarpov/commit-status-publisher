<%@ include file="/include-internal.jsp" %>
<jsp:useBean id="projectExternalId" type="java.lang.String" scope="request"/>
<jsp:useBean id="hiddenBuildTypes" type="java.util.List" scope="request"/>
<jsp:useBean id="hiddenBuildTypesNumber" type="java.lang.Integer" scope="request"/>

<div>
  <div class="list">
    <c:choose
      ><c:when test="${hiddenBuildTypesNumber > 0}"
        ><c:forEach items="${hiddenBuildTypes}" var="bt" varStatus="status"
          ><c:if test="${status.count <= 10}"
            ><div class="entry">
              <a href="#" onclick="return BS.VisibleBuildTypesDialog.showSingleBuildType('${projectExternalId}', '${bt.buildTypeId}');"
                 class="right" title="Add to Overview">show</a>
              <bs:buildTypeLink buildType="${bt}" />
            </div></c:if
        ></c:forEach
      ><c:if test="${hiddenBuildTypesNumber > 10}"
        ><div>...and ${hiddenBuildTypesNumber - 10} more</div></c:if
      ></c:when
      ><c:otherwise
        ><div>To hide a build configuration from the Projects Overview, click the link below.<br />
              You can always bring it back later.</div></c:otherwise
    ></c:choose>
  </div>
  <div class="action-bar">
    <a href="#" onclick="BS.VisibleBuildTypesDialog.showForProject('${projectExternalId}'); return false"
        title="Configure build configurations order">Hide, show or reorder build configurations...</a>
    <forms:progressRing className="progressRingInline" id="vp_${projectExternalId}" style="visibility:hidden"/>
  </div>
</div>