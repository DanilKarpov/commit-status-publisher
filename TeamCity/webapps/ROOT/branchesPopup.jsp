<%@include file="/include-internal.jsp"%>
<jsp:useBean id="branches" type="java.util.Collection" scope="request"/>
<jsp:useBean id="targetFieldId" type="java.lang.String" scope="request"/>
<jsp:useBean id="selectMode" type="java.lang.String" scope="request"/>

<style type="text/css">
  .branchesContainer .itemList, .branchesContainer .menuList {
    width: 20em;
  }

  div.popupTitle {
    padding: 4px 0 4px 0;
  }

  ul.menuList {
    padding: 0px 2px 0 2px;
    margin-left: 0;
  }

  ul.menuList li {
    list-style: none;
    padding: 2px;
  }

  ul.menuList li a {
    display: inline;
  }

  .helperButtonBlock {
    margin-top: 15px;
  }

  .helperButtonBlock .btn.submitButton {
    margin-right: 10px;
  }

  .helperButtonBlock .btn.cancel {
    margin-right: 0px;
  }

</style>

<div class="branchesContainer" id="branchesContainerId" style="padding-top: 5px">
  <c:if test="${empty branches}">
    <div>No branches to show</div>
  </c:if>
  <c:set var="containerId"><bs:id/></c:set>
  <form>
  <c:if test="${fn:length(branches) > 10}">
    <bs:inplaceFilter containerId="${containerId}" activate="true" filterText="&lt;filter branches>"/>
  </c:if>
  <c:choose>
    <c:when test="${selectMode eq 'branchFilter'}">
      <ul class="itemsList" id="${containerId}">
        <li class="inplaceFiltered">
          <forms:checkbox id="__all_branches" name="branch__all_branches" value="*"/>
          <label for="__all_branches"><em>&lt;all branches&gt;</em></label>
        </li>
        <c:forEach items="${branches}" var="branch" varStatus="pos">
          <c:set var="branch" value="${fn:escapeXml(branch)}"/>
          <li class="inplaceFiltered">
            <forms:checkbox id="branch_${branch}" name="branch_${branch}" value="${branch}"/>
            <label for="branch_${branch}">${branch}</label>
          </li>
        </c:forEach>
      </ul>
    </c:when>
    <c:otherwise>
      <ul class="menuList" id="${containerId}">
        <c:forEach items="${branches}" var="branch">
          <li class="inplaceFiltered"><c:out value="${branch}"/></li>
        </c:forEach>
      </ul>
      <script type="text/javascript">
        $j('#${containerId}').click(function(event) {
          var fieldId = '${util:forJS(targetFieldId, true, false)}'.replace(/\./g, '\\.');
          $j('#' + fieldId).val($j(event.target).text());
          BS.BranchesPopup.hidePopup(0);
        });
      </script>
    </c:otherwise>
  </c:choose>

  <c:if test="${selectMode eq 'branchFilter'}">
  <div class="helperButtonBlock">
      <forms:submit onclick="return BS.BranchesPopup.appendSelected('+:', '${containerId}', '${util:forJS(targetFieldId, true, true)}', BS.BranchFilterHelperPopup);" label="Include selected"/>
      <forms:submit onclick="return BS.BranchesPopup.appendSelected('-:', '${containerId}', '${util:forJS(targetFieldId, true, true)}', BS.BranchFilterHelperPopup);" label="Exclude selected"/>
      <forms:cancel onclick="BS.BranchesPopup.hidePopup(0); BS.BranchFilterHelperPopup.hidePopup(0)"/>
  </div>
  </c:if>
  </form>
</div>